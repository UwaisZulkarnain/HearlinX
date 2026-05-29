import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../ui/app_styles.dart';
import '../widgets/app_shell.dart';

class CoordinatorDashboardScreen extends StatefulWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  State<CoordinatorDashboardScreen> createState() =>
      _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState
    extends State<CoordinatorDashboardScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  String _coordinatorName = '';
  _MonthlySummary _summary = const _MonthlySummary();
  List<_FollowUpItem> _followUps = const [];
  List<_HospitalScreeningItem> _screenings = const [];

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

      // Get coordinator name
      final displayName = await _authService.getDisplayName();

      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/reports/monthly'), headers: headers),
        http.get(Uri.parse('$baseUrl/followups/'), headers: headers),
        http.get(
          Uri.parse('$baseUrl/screenings/?today=true'),
          headers: headers,
        ),
      ]);

      for (final response in responses) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(_parseErrorMessage(response.body));
        }
      }

      final summaryJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final followUpJson = jsonDecode(responses[1].body) as List<dynamic>;
      final screeningJson = jsonDecode(responses[2].body) as List<dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _coordinatorName = displayName;
        _summary = _MonthlySummary.fromJson(summaryJson);
        _followUps = followUpJson
            .map((item) => _FollowUpItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _screenings = screeningJson
            .map(
              (item) =>
                  _HospitalScreeningItem.fromJson(item as Map<String, dynamic>),
            )
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
      final detail = payload['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    } catch (_) {}
    return 'Ralat tidak diketahui';
  }

  Future<void> _updateFollowUpStatus(String id, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi telah tamat. Sila log masuk semula.');
      }

      final response = await _apiService.client.patch(
        Uri.parse('${_apiService.baseEndpoint}/followups/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseErrorMessage(response.body));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status susulan berjaya dikemas kini'),
          backgroundColor: AppStyles.success,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppStyles.danger,
        ),
      );
    }
  }

  Widget _metricCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppStyles.surfaceCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppStyles.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppStyles.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  String _getLastScreeningTime() {
    if (_screenings.isEmpty) {
      return '-';
    }
    final lastScreening = _screenings.first;
    return DateFormat('hh:mm a').format(lastScreening.screeningDate.toLocal());
  }

  Widget _buildBody() {
    final t = context.watch<LanguageProvider>().text;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 120),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppStyles.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppStyles.pagePadding,
        children: [
          // Greeting
          Text(
            t.welcomeGreeting(_coordinatorName),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppStyles.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(_summary.hospitalName, style: AppStyles.headingStyle),
          const SizedBox(height: 6),
          Text(
            "${t.monthlySummary} ${DateFormat('MMMM yyyy').format(DateTime(_summary.year, _summary.month))}",
            style: const TextStyle(color: AppStyles.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _metricCard(
                t.totalScreenings,
                _summary.totalScreenings,
                AppStyles.accent,
              ),
              const SizedBox(width: 12),
              _metricCard(t.pass, _summary.totalPass, AppStyles.success),
              const SizedBox(width: 12),
              _metricCard(t.refer, _summary.totalRefer, AppStyles.danger),
            ],
          ),
          const SizedBox(height: 18),
          // Additional Info Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppStyles.surfaceCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.lastScreening,
                        style: const TextStyle(
                          color: AppStyles.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLastScreeningTime(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppStyles.surfaceCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.activeScreeners,
                        style: const TextStyle(
                          color: AppStyles.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_screenings.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: t.followupQueue,
            child: _followUps.isEmpty
                ? Text(
                    t.noPendingFollowups,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  )
                : Column(
                    children: _followUps.take(4).map((item) {
                      final dueText = item.dueDate == null
                          ? 'Tiada tarikh'
                          : DateFormat('d MMM yyyy').format(item.dueDate!);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.babySystemId,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tarikh: $dueText'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _followUpActionButton(
                                  t.markContacted,
                                  item.id,
                                  'contacted',
                                ),
                                _followUpActionButton(
                                  t.bookAppointment,
                                  item.id,
                                  'appointment_booked',
                                ),
                                _followUpActionButton(
                                  t.escalate,
                                  item.id,
                                  'escalated',
                                ),
                                _followUpActionButton(
                                  t.close,
                                  item.id,
                                  'closed',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: t.todayScreenings,
            child: _screenings.isEmpty
                ? Text(
                    t.todayScreeningRecorded,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  )
                : Column(
                    children: _screenings.take(5).map((item) {
                      final timeText = DateFormat(
                        'hh:mm a',
                      ).format(item.screeningDate.toLocal());
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.babySystemId,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(timeText),
                        trailing: SizedBox(
                          width: 72,
                          child: Text(
                            item.isRefer ? t.refer : t.pass,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: item.isRefer
                                  ? AppStyles.danger
                                  : AppStyles.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return AppShell(title: t.hospitalDashboard, child: _buildBody());
  }

  Widget _followUpActionButton(String label, String id, String status) {
    return OutlinedButton(
      onPressed: () => _updateFollowUpStatus(id, status),
      style: AppStyles.outlineButtonStyle().copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      child: Text(label),
    );
  }
}

class _MonthlySummary {
  const _MonthlySummary({
    this.hospitalName = '',
    this.year = 0,
    this.month = 0,
    this.totalScreenings = 0,
    this.totalPass = 0,
    this.totalRefer = 0,
  });

  factory _MonthlySummary.fromJson(Map<String, dynamic> json) {
    return _MonthlySummary(
      hospitalName: json['hospital_name'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalPass: json['total_pass'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
    );
  }

  final String hospitalName;
  final int year;
  final int month;
  final int totalScreenings;
  final int totalPass;
  final int totalRefer;
}

class _FollowUpItem {
  const _FollowUpItem({
    required this.id,
    required this.babySystemId,
    required this.dueDate,
  });

  factory _FollowUpItem.fromJson(Map<String, dynamic> json) {
    return _FollowUpItem(
      id: json['id'] as String? ?? '',
      babySystemId: json['baby_system_id'] as String? ?? '',
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
    );
  }

  final String id;
  final String babySystemId;
  final DateTime? dueDate;
}

class _HospitalScreeningItem {
  const _HospitalScreeningItem({
    required this.babySystemId,
    required this.earLeft,
    required this.earRight,
    required this.screeningDate,
  });

  factory _HospitalScreeningItem.fromJson(Map<String, dynamic> json) {
    return _HospitalScreeningItem(
      babySystemId: json['baby_system_id'] as String? ?? '',
      earLeft: json['ear_left'] as String? ?? '',
      earRight: json['ear_right'] as String? ?? '',
      screeningDate: DateTime.parse(json['screening_date'] as String),
    );
  }

  final String babySystemId;
  final String earLeft;
  final String earRight;
  final DateTime screeningDate;

  bool get isRefer => earLeft == 'refer' || earRight == 'refer';

  String get resultLabel => isRefer ? 'REFER' : 'PASS';
}
