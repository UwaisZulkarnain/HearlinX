import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import '../ui/app_styles.dart';

class FailedSyncsScreen extends StatefulWidget {
  const FailedSyncsScreen({super.key});

  @override
  State<FailedSyncsScreen> createState() => _FailedSyncsScreenState();
}

class _FailedSyncsScreenState extends State<FailedSyncsScreen> {
  final _offlineService = OfflineService();
  final _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _failedRecords = const [];

  @override
  void initState() {
    super.initState();
    _loadFailedRecords();
  }

  Future<void> _loadFailedRecords() async {
    final records = await _offlineService.getFailedScreenings();
    if (!mounted) {
      return;
    }

    setState(() {
      _failedRecords = records;
      _isLoading = false;
    });
  }

  Future<void> _retryRecord(int id) async {
    await _offlineService.retryFailedScreening(id);
    await _loadFailedRecords();
  }

  Future<void> _deleteRecord(int id) async {
    final t = context.read<LanguageProvider>().text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteRecord),
        content: Text(t.confirmDeleteFailed),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppStyles.danger),
            child: Text(t.deleteRecord),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _offlineService.deleteFailedScreening(id);
      await _loadFailedRecords();
    }
  }

  Future<void> _retryAll() async {
    final t = context.read<LanguageProvider>().text;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    for (final record in _failedRecords) {
      final id = record['id'];
      if (id is int) {
        await _offlineService.retryFailedScreening(id);
      }
    }

    final isOnline = await ApiConfig.checkConnectivity();
    if (!isOnline) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.noInternet),
          backgroundColor: AppStyles.warning,
        ),
      );
      await _loadFailedRecords();
      return;
    }

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final result = await _offlineService.syncPendingScreenings(token);
    if (result['authError'] == true && mounted) {
      await _authService.logout();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.sessionExpired),
          backgroundColor: AppStyles.danger,
          duration: const Duration(seconds: 4),
        ),
      );
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    if (result['failed'] > 0 && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${result['failed']} ${t.syncFailedMessage}'),
          backgroundColor: AppStyles.warning,
        ),
      );
    }

    await _loadFailedRecords();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: AppStyles.brand,
        title: Text(
          t.failedSyncsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _failedRecords.isEmpty
          ? Center(child: Text(t.noFailedSyncs))
          : RefreshIndicator(
              onRefresh: _loadFailedRecords,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _retryAll,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(t.retryAll),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppStyles.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _failedRecords.length,
                      itemBuilder: (context, index) {
                        final record = _failedRecords[index];
                        final id = record['id'];
                        final babyId = record['baby_id'] as String? ?? '-';
                        final errorCode =
                            record['error_code'] as String? ?? '-';
                        final errorMessage =
                            record['error_message'] as String? ?? '-';
                        final createdAt =
                            record['created_at'] as String? ?? '-';
                        final attempts = record['sync_attempts'] as int? ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppStyles.danger.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppStyles.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      babyId,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _detailRow(t.babyId, babyId),
                              _detailRow(t.errorCode, errorCode),
                              _detailRow(t.attempts, '$attempts'),
                              _detailRow(t.createdAt, createdAt),
                              _detailRow(t.errorMessageLabel, errorMessage),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: id is int
                                          ? () => _retryRecord(id)
                                          : null,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: Text(t.retry),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppStyles.accent,
                                        side: const BorderSide(
                                          color: AppStyles.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: id is int
                                          ? () => _deleteRecord(id)
                                          : null,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      label: Text(t.deleteRecord),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppStyles.danger,
                                        side: const BorderSide(
                                          color: AppStyles.danger,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppStyles.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppStyles.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
