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

  String _formatDateTime(DateTime dateTime) {
    final languageProvider = context.read<LanguageProvider>();
    final isBm = languageProvider.lang == 'ms';

    final months = isBm
        ? [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agu',
            'Sep',
            'Okt',
            'Nov',
            'Dis',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute';
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
        label: Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
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
            onPressed: () =>
                Navigator.of(context).pushNamed('/screening-entry'),
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
            onPressed: () =>
                Navigator.of(context).pushNamed('/coordinator-dashboard'),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasPending
            ? AppStyles.warning.withValues(alpha: 0.12)
            : AppStyles.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPending
              ? AppStyles.warning.withValues(alpha: 0.3)
              : AppStyles.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
            color: hasPending ? AppStyles.warning : AppStyles.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasPending ? '$_pendingSyncCount ${t.pendingSync}' : t.allSaved,
              style: TextStyle(
                color: hasPending ? AppStyles.warning : AppStyles.success,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasPending)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppStyles.warning,
                shape: BoxShape.circle,
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D6E63), Color(0xFF1A9B87)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'DengarTrack',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
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
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F8F5), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFF18C7A5),
                                width: 4,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF18C7A5,
                                ).withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
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
                                user.fullName.isEmpty
                                    ? user.staffId
                                    : user.fullName,
                                style: const TextStyle(
                                  color: AppStyles.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                                softWrap: true,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(DateTime.now()),
                                style: TextStyle(
                                  color: AppStyles.textSecondary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18C7A5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _roleLabel(user.role),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
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
