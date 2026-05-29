import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import '../ui/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _offlineService = OfflineService();

  User? _user;
  bool _isLoading = true;
  int _pendingSyncCount = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startAutoSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) {
      return;
    }

    setState(() {
      _user = user;
      _isLoading = false;
    });
    await _syncPendingScreenings();
  }

  void _startAutoSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _syncPendingScreenings();
    });
  }

  Future<void> _refreshSyncStatus() async {
    final count = await _offlineService.getPendingScreeningCount();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingSyncCount = count;
    });
  }

  Future<void> _syncPendingScreenings() async {
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      await _offlineService.syncPendingScreenings(token);
    }
    await _refreshSyncStatus();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  String _roleLabel(String role) {
    final t = context.read<LanguageProvider>().text;

    switch (role) {
      case User.roleScreener:
        return t.screener;
      case User.roleCoordinator:
        return t.coordinator;
      case User.roleUnhsCoordinator:
        return t.unhsCoordinator;
      case User.roleMoh:
        return 'MoH / KKM';
      default:
        return t.user;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: AppStyles.primaryButtonStyle(),
      ),
    );
  }

  List<Widget> _buildRoleActions(User user) {
    final t = context.watch<LanguageProvider>().text;

    switch (user.role) {
      case User.roleScreener:
        return [
          _buildActionButton(
            icon: Icons.post_add_rounded,
            label: t.newScreening,
            onPressed: () => Navigator.of(context).pushNamed('/screening-entry'),
          ),
          const SizedBox(height: 14),
          _buildActionButton(
            icon: Icons.summarize_rounded,
            label: t.myShiftSummary,
            onPressed: () => Navigator.of(context).pushNamed('/shift-summary'),
          ),
        ];
      case User.roleCoordinator:
        return [
          _buildActionButton(
            icon: Icons.space_dashboard_rounded,
            label: t.hospitalDashboard,
            onPressed: () => Navigator.of(context).pushNamed('/coordinator-dashboard'),
          ),
        ];
      case User.roleUnhsCoordinator:
        return [
          _buildActionButton(
            icon: Icons.assessment_rounded,
            label: t.unhsDashboard,
            onPressed: () => Navigator.of(context).pushNamed('/unhs-dashboard'),
          ),
        ];
      case User.roleMoh:
        return [
          _buildActionButton(
            icon: Icons.public_rounded,
            label: t.nationalDashboard,
            onPressed: () => Navigator.of(context).pushNamed('/moh-dashboard'),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildSyncStatus() {
    final t = context.watch<LanguageProvider>().text;
    final hasPending = _pendingSyncCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasPending
            ? AppStyles.warning.withValues(alpha: 0.12)
            : AppStyles.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPending ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
            color: hasPending ? AppStyles.warning : AppStyles.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hasPending ? '$_pendingSyncCount ${t.pendingSync}' : t.allSaved,
              style: TextStyle(
                color: hasPending ? AppStyles.warning : AppStyles.success,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final languageProvider = context.watch<LanguageProvider>();
    final t = languageProvider.text;

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: AppStyles.brand,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'HearLinX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: t.logout,
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
          TextButton(
            onPressed: languageProvider.toggleLang,
            child: Text(
              languageProvider.lang == 'en' ? 'BM' : 'EN',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Text(
                    t.userLoadError,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  ),
                )
              : SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: AppStyles.formPagePadding,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: AppStyles.surfaceCard(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.welcomeHome,
                                    style: TextStyle(
                                      color: AppStyles.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user.fullName.isEmpty ? user.staffId : user.fullName,
                                    style: const TextStyle(
                                      color: AppStyles.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppStyles.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _roleLabel(user.role),
                                      style: const TextStyle(
                                        color: AppStyles.brand,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSyncStatus(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ..._buildRoleActions(user),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_rounded),
                                label: Text(
                                  t.logout,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: AppStyles.outlineButtonStyle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
