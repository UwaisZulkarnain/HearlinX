import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../ui/app_styles.dart';
import '../widgets/app_shell.dart';

class UnhsDashboardScreen extends StatefulWidget {
  const UnhsDashboardScreen({super.key});

  @override
  State<UnhsDashboardScreen> createState() => _UnhsDashboardScreenState();
}

class _UnhsDashboardScreenState extends State<UnhsDashboardScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  _UnhsMonthlySummary _summary = const _UnhsMonthlySummary();
  List<_AuditItem> _auditItems = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi telah tamat. Sila log masuk semula.');
      }

      final headers = {'Authorization': 'Bearer $token'};
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/reports/monthly'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/audit-logs/recent'),
          headers: headers,
        ),
      ]);

      for (final response in responses) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(_parseErrorMessage(response.body));
        }
      }

      final summaryJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final auditJson = jsonDecode(responses[1].body) as List<dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = _UnhsMonthlySummary.fromJson(summaryJson);
        _auditItems = auditJson
            .map((item) => _AuditItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['detail'] as String? ?? 'Ralat tidak diketahui';
    } catch (_) {
      return 'Ralat tidak diketahui';
    }
  }

  Widget _body() {
    final t = context.watch<LanguageProvider>().text;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppStyles.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppStyles.pagePadding,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Color(0xFF18C7A5), width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_summary.hospitalName, style: AppStyles.headingStyle),
                const SizedBox(height: 8),
                Text(
                  "${t.monthlyReport} ${DateFormat('MMMM yyyy').format(DateTime(_summary.year, _summary.month))}",
                  style: const TextStyle(color: AppStyles.textSecondary),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryChip(
                      t.totalScreenings,
                      _summary.totalScreenings.toString(),
                      AppStyles.accent,
                    ),
                    _summaryChip(
                      t.pass,
                      _summary.totalPass.toString(),
                      AppStyles.success,
                    ),
                    _summaryChip(
                      t.refer,
                      _summary.totalRefer.toString(),
                      AppStyles.danger,
                    ),
                    _summaryChip(
                      t.notTested,
                      _summary.totalNotTested.toString(),
                      AppStyles.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Color(0xFF18C7A5), width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.recentAudit,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_auditItems.isEmpty)
                  Text(
                    t.noAudit,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  )
                else
                  ..._auditItems.map((item) {
                    Color getActionDotColor(String action) {
                      if (action.contains('CREATE')) {
                        return const Color(0xFF26D07C);
                      } else if (action.contains('UPDATE')) {
                        return const Color(0xFF2563EB);
                      } else if (action.contains('DEACTIVATE')) {
                        return const Color(0xFFE85D75);
                      }
                      return const Color(0xFF6B7C85);
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: getActionDotColor(item.action),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      title: Text(
                        item.actorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${item.action} \u2022 ${item.tableName}'),
                      trailing: SizedBox(
                        width: 92,
                        child: Text(
                          DateFormat(
                            'd MMM, hh:mm a',
                          ).format(item.createdAt.toLocal()),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppStyles.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    final gradientColors = {
      AppStyles.accent: const [Color(0xFFB2F1DF), Color(0xFFE0F9F6)],
      AppStyles.success: const [Color(0xFFC6F6D5), Color(0xFFF0FDF4)],
      AppStyles.danger: const [Color(0xFFFECACA), Color(0xFFFEF2F2)],
      AppStyles.warning: const [Color(0xFFFDE68A), Color(0xFFFEF9C3)],
    };

    IconData getIcon(String label) {
      if (label.contains('Screening') || label.contains('Saringan')) {
        return Icons.person_search_rounded;
      } else if (label.contains('Pass') || label.contains('Lulus')) {
        return Icons.check_circle_rounded;
      } else if (label.contains('Refer') || label.contains('Rujuk')) {
        return Icons.arrow_forward_rounded;
      } else if (label.contains('Not') || label.contains('Belum')) {
        return Icons.help_outline_rounded;
      }
      return Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors[color] ?? [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getIcon(label), size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppStyles.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return AppShell(title: t.unhsDashboard, child: _body());
  }
}

class _UnhsMonthlySummary {
  const _UnhsMonthlySummary({
    this.hospitalName = '',
    this.year = 0,
    this.month = 0,
    this.totalScreenings = 0,
    this.totalPass = 0,
    this.totalRefer = 0,
    this.totalNotTested = 0,
  });

  factory _UnhsMonthlySummary.fromJson(Map<String, dynamic> json) {
    return _UnhsMonthlySummary(
      hospitalName: json['hospital_name'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalPass: json['total_pass'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
      totalNotTested: json['total_not_tested'] as int? ?? 0,
    );
  }

  final String hospitalName;
  final int year;
  final int month;
  final int totalScreenings;
  final int totalPass;
  final int totalRefer;
  final int totalNotTested;
}

class _AuditItem {
  const _AuditItem({
    required this.actorName,
    required this.action,
    required this.tableName,
    required this.createdAt,
  });

  factory _AuditItem.fromJson(Map<String, dynamic> json) {
    return _AuditItem(
      actorName: json['actor_name'] as String? ?? '',
      action: json['action'] as String? ?? '',
      tableName: json['table_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String actorName;
  final String action;
  final String tableName;
  final DateTime createdAt;
}
