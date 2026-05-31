import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../l10n/app_text.dart';
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
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/reports/monthly'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/followups/'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/screenings/?today=true'),
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
    await _patchFollowUp(id, {'status': status});
  }

  Future<void> _patchFollowUp(String id, Map<String, dynamic> payload) async {
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
        body: jsonEncode(payload),
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

  Future<List<_FollowUpEvent>> _fetchFollowUpEvents(String id) async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi telah tamat. Sila log masuk semula.');
    }
    final response = await _apiService.client.get(
      Uri.parse('${_apiService.baseEndpoint}/followups/$id/events'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseErrorMessage(response.body));
    }
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) => _FollowUpEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Widget _metricCard(String label, int value, Color color) {
    final gradientColors = {
      AppStyles.accent: const [Color(0xFFB2F1DF), Color(0xFFE0F9F6)],
      AppStyles.success: const [Color(0xFFC6F6D5), Color(0xFFF0FDF4)],
      AppStyles.danger: const [Color(0xFFFECACA), Color(0xFFFEF2F2)],
      AppStyles.warning: const [Color(0xFFFDE68A), Color(0xFFFFFBEB)],
    };

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        height: 120,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
        color: const Color(0xFF18C7A5),
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
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
      color: const Color(0xFF18C7A5),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppStyles.pagePadding,
        children: [
          // Greeting
          Text(
            t.welcomeGreeting(_coordinatorName),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 12),
          Row(
            children: [
              _metricCard(t.followupQueue, _followUps.length, AppStyles.accent),
              const SizedBox(width: 12),
              _metricCard(t.ltfu, _summary.totalLtfu, AppStyles.warning),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Color(0xFF18C7A5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.lastScreening,
                            style: const TextStyle(
                              color: AppStyles.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
                      Row(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: Color(0xFF18C7A5),
                          ),
                          const SizedBox(width: 6),
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
                        ],
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
                        onTap: () => _showFollowUpDetails(item),
                        title: Text(
                          item.babySystemId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Tarikh: $dueText'),
                                _urgencyBadge(item, t),
                                Text('Status: ${item.status}'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _followUpActionButton(
                                  t.markContacted,
                                  item.id,
                                  'contacted',
                                  outlineColor: const Color(0xFF18C7A5),
                                ),
                                _followUpActionButton(
                                  t.bookAppointment,
                                  item.id,
                                  'appointment_booked',
                                  outlineColor: const Color(0xFF2563EB),
                                ),
                                _followUpActionButton(
                                  t.escalate,
                                  item.id,
                                  'escalated',
                                  outlineColor: const Color(0xFFEA580C),
                                ),
                                _followUpActionButton(
                                  t.complete,
                                  item.id,
                                  'completed',
                                  outlineColor: AppStyles.success,
                                ),
                                _followUpActionButton(
                                  t.markLtfu,
                                  item.id,
                                  'lost_to_followup',
                                  outlineColor: AppStyles.warning,
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

  Widget _followUpActionButton(
    String label,
    String id,
    String status, {
    Color outlineColor = const Color(0xFF18C7A5),
  }) {
    return OutlinedButton(
      onPressed: () => _updateFollowUpStatus(id, status),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: outlineColor, width: 1.5),
        foregroundColor: outlineColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _showFollowUpDetails(_FollowUpItem item) async {
    final t = context.read<LanguageProvider>().text;
    final notesController = TextEditingController(text: item.notes ?? '');
    final reasonController = TextEditingController(text: item.ltfuReason ?? '');
    final appointmentController = TextEditingController(
      text: item.appointmentDate == null
          ? ''
          : DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(item.appointmentDate!.toLocal()),
    );
    String selectedStatus = item.status;

    try {
      final events = await _fetchFollowUpEvents(item.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.followupDetails, style: AppStyles.headingStyle),
                      const SizedBox(height: 6),
                      Text(
                        item.babySystemId,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(labelText: t.status),
                        items:
                            const [
                              'pending',
                              'contacted',
                              'appointment_booked',
                              'escalated',
                              'completed',
                              'lost_to_followup',
                              'closed',
                            ].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: appointmentController,
                        decoration: InputDecoration(
                          labelText: t.appointmentDate,
                          hintText: 'yyyy-MM-dd HH:mm',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(labelText: t.ltfuReason),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(labelText: t.notes),
                      ),
                      const SizedBox(height: 10),
                      Text('${t.contactAttempts}: ${item.contactAttempts}'),
                      const SizedBox(height: 16),
                      Text(
                        t.timeline,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (events.isEmpty)
                        const Text(
                          'No timeline events yet.',
                          style: TextStyle(color: AppStyles.textSecondary),
                        )
                      else
                        ...events.map(
                          (event) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              event.action,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (event.fromStatus != null ||
                                    event.toStatus != null)
                                  '${event.fromStatus ?? '-'} -> ${event.toStatus ?? '-'}',
                                if ((event.notes ?? '').isNotEmpty)
                                  event.notes!,
                              ].join('\n'),
                            ),
                            trailing: Text(
                              DateFormat(
                                'd MMM\nhh:mm a',
                              ).format(event.createdAt.toLocal()),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppStyles.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final payload = <String, dynamic>{
                              'status': selectedStatus,
                              'notes': notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              'ltfu_reason':
                                  reasonController.text.trim().isEmpty
                                  ? null
                                  : reasonController.text.trim(),
                            };
                            final appointmentText = appointmentController.text
                                .trim();
                            if (appointmentText.isNotEmpty) {
                              payload['appointment_date'] = DateTime.parse(
                                appointmentText,
                              ).toIso8601String();
                            }
                            Navigator.of(context).pop();
                            await _patchFollowUp(item.id, payload);
                          },
                          child: Text(t.save),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppStyles.danger,
        ),
      );
    } finally {
      notesController.dispose();
      reasonController.dispose();
      appointmentController.dispose();
    }
  }

  Widget _urgencyBadge(_FollowUpItem item, AppText t) {
    final urgency = item.urgency;
    final (label, color) = switch (urgency) {
      'ltfu' => (t.ltfu, AppStyles.warning),
      'red' => (t.redRisk, AppStyles.danger),
      'amber' => (
        item.daysOverdue > 0 ? '${t.overdue} ${item.daysOverdue}h' : t.overdue,
        const Color(0xFFEA580C),
      ),
      _ => (t.newFollowup, AppStyles.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
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
    this.totalLtfu = 0,
  });

  factory _MonthlySummary.fromJson(Map<String, dynamic> json) {
    return _MonthlySummary(
      hospitalName: json['hospital_name'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalPass: json['total_pass'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
      totalLtfu: json['total_ltfu'] as int? ?? 0,
    );
  }

  final String hospitalName;
  final int year;
  final int month;
  final int totalScreenings;
  final int totalPass;
  final int totalRefer;
  final int totalLtfu;
}

class _FollowUpItem {
  const _FollowUpItem({
    required this.id,
    required this.babySystemId,
    required this.dueDate,
    required this.status,
    required this.urgency,
    required this.daysOverdue,
    required this.notes,
    required this.appointmentDate,
    required this.ltfuReason,
    required this.contactAttempts,
  });

  factory _FollowUpItem.fromJson(Map<String, dynamic> json) {
    return _FollowUpItem(
      id: json['id'] as String? ?? '',
      babySystemId: json['baby_system_id'] as String? ?? '',
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'new',
      daysOverdue: json['days_overdue'] as int? ?? 0,
      notes: json['notes'] as String?,
      appointmentDate: json['appointment_date'] == null
          ? null
          : DateTime.parse(json['appointment_date'] as String),
      ltfuReason: json['ltfu_reason'] as String?,
      contactAttempts: json['contact_attempts'] as int? ?? 0,
    );
  }

  final String id;
  final String babySystemId;
  final DateTime? dueDate;
  final String status;
  final String urgency;
  final int daysOverdue;
  final String? notes;
  final DateTime? appointmentDate;
  final String? ltfuReason;
  final int contactAttempts;
}

class _FollowUpEvent {
  const _FollowUpEvent({
    required this.action,
    required this.createdAt,
    this.fromStatus,
    this.toStatus,
    this.notes,
  });

  factory _FollowUpEvent.fromJson(Map<String, dynamic> json) {
    return _FollowUpEvent(
      action: json['action'] as String? ?? '',
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String action;
  final String? fromStatus;
  final String? toStatus;
  final String? notes;
  final DateTime createdAt;
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
