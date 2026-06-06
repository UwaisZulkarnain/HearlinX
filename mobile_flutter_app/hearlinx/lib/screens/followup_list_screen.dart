import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../l10n/app_text.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../ui/app_styles.dart';
import '../widgets/app_shell.dart';

class FollowUpListScreen extends StatefulWidget {
  const FollowUpListScreen({super.key});

  @override
  State<FollowUpListScreen> createState() => _FollowUpListScreenState();
}

class _FollowUpListScreenState extends State<FollowUpListScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  List<_FollowUpListItem> _allFollowUps = [];
  List<_FollowUpListItem> _filteredFollowUps = [];
  String _searchQuery = '';
  String _filterUrgency = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final t = context.read<LanguageProvider>().text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(t.sessionExpired);
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/followups/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      final items = decoded
          .map(
            (item) => _FollowUpListItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      items.sort((a, b) {
        final urgencyOrder = {'ltfu': 0, 'red': 1, 'amber': 2, 'new': 3};
        final orderA = urgencyOrder[a.urgency] ?? 99;
        final orderB = urgencyOrder[b.urgency] ?? 99;
        if (orderA != orderB) return orderA.compareTo(orderB);
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        return 0;
      });

      if (!mounted) return;

      setState(() {
        _allFollowUps = items;
        _filteredFollowUps = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    var filtered = _allFollowUps;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) => item.babySystemId.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    if (_filterUrgency != 'all') {
      filtered = filtered
          .where((item) => item.urgency == _filterUrgency)
          .toList();
    }

    setState(() {
      _filteredFollowUps = filtered;
    });
  }

  String _translateStatus(String status, AppText t) {
    return switch (status) {
      'pending' => t.statusPending,
      'contacted' => t.statusContacted,
      'appointment_booked' => t.statusAppointmentBooked,
      'escalated' => t.statusEscalated,
      'completed' => t.statusCompleted,
      'lost_to_followup' => t.statusLostToFollowup,
      'closed' => t.statusClosed,
      _ => status,
    };
  }

  String _translateUrgency(String urgency, AppText t) {
    return switch (urgency) {
      'ltfu' => t.ltfu,
      'red' => t.redRisk,
      'amber' => t.overdue,
      'new' => t.newFollowup,
      _ => urgency,
    };
  }

  Color _urgencyColor(String urgency) {
    return switch (urgency) {
      'ltfu' => AppStyles.warning,
      'red' => AppStyles.danger,
      'amber' => const Color(0xFFEA580C),
      _ => AppStyles.accent,
    };
  }

  Future<void> _quickAction(
    String id,
    String status,
    String successMessage,
  ) async {
    final t = context.read<LanguageProvider>().text;
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) throw Exception(t.sessionExpired);

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/followups/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppStyles.success,
          duration: const Duration(seconds: 2),
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppStyles.danger,
        ),
      );
    }
  }

  Future<void> _confirmAndQuickAction(
    String id,
    String status,
    String confirmMessage,
    String successMessage,
  ) async {
    final t = context.read<LanguageProvider>().text;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.confirmAction),
        content: Text(confirmMessage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppStyles.accent),
            child: Text(t.yes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _quickAction(id, status, successMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return AppShell(
      title: t.allFollowUpsTitle,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: t.searchByBabyId,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', t.filterAll, AppStyles.textSecondary),
                  const SizedBox(width: 8),
                  _filterChip('ltfu', t.filterLtfu, AppStyles.warning),
                  const SizedBox(width: 8),
                  _filterChip('red', t.filterRed, AppStyles.danger),
                  const SizedBox(width: 8),
                  _filterChip('amber', t.filterAmber, const Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  _filterChip('new', t.filterNew, AppStyles.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Count and last updated
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredFollowUps.length} ${t.followupQueue.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppStyles.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${t.lastUpdated}: ${DateFormat('d MMM, hh:mm a').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppStyles.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadData,
                          child: Text(t.retry),
                        ),
                      ],
                    ),
                  )
                : _filteredFollowUps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppStyles.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.noFollowUpsFound,
                          style: TextStyle(color: AppStyles.textSecondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppStyles.accent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredFollowUps.length,
                      itemBuilder: (context, index) {
                        final item = _filteredFollowUps[index];
                        return _buildFollowUpCard(item, t);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, Color color) {
    final isSelected = _filterUrgency == value;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : color,
        ),
      ),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        setState(() {
          _filterUrgency = selected ? value : 'all';
          _applyFilter();
        });
      },
    );
  }

  Widget _buildFollowUpCard(_FollowUpListItem item, AppText t) {
    final urgencyColor = _urgencyColor(item.urgency);
    final dueText = item.dueDate == null
        ? t.noDueDate
        : DateFormat('d MMM yyyy').format(item.dueDate!);
    final isOverdue = item.daysOverdue > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.babySystemId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _translateUrgency(item.urgency, t),
                              style: TextStyle(
                                color: urgencyColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isOverdue)
                            Text(
                              '${item.daysOverdue} ${t.daysOverdueText}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppStyles.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dueText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue
                            ? AppStyles.danger
                            : AppStyles.textSecondary,
                        fontWeight: isOverdue
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _translateStatus(item.status, t),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionButton(
                  t.markContacted,
                  Colors.green,
                  () => _quickAction(item.id, 'contacted', t.markedAsContacted),
                ),
                _actionButton(
                  t.bookAppointment,
                  Colors.blue,
                  () => _quickAction(
                    item.id,
                    'appointment_booked',
                    t.appointmentBooked,
                  ),
                ),
                _actionButton(
                  t.escalate,
                  Colors.orange,
                  () => _confirmAndQuickAction(
                    item.id,
                    'escalated',
                    t.confirmEscalate,
                    t.caseEscalated,
                  ),
                ),
                _actionButton(
                  t.complete,
                  AppStyles.success,
                  () => _confirmAndQuickAction(
                    item.id,
                    'completed',
                    t.confirmComplete,
                    t.caseCompleted,
                  ),
                ),
                _actionButton(
                  t.markLtfu,
                  AppStyles.warning,
                  () => _confirmAndQuickAction(
                    item.id,
                    'lost_to_followup',
                    t.confirmMarkLtfu,
                    t.caseMarkedLtfu,
                  ),
                ),
              ],
            ),
          ),

          // Tap hint
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              t.tapToViewDetails,
              style: TextStyle(
                fontSize: 11,
                color: AppStyles.textSecondary.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FollowUpListItem {
  const _FollowUpListItem({
    required this.id,
    required this.babySystemId,
    required this.dueDate,
    required this.status,
    required this.urgency,
    required this.daysOverdue,
    required this.contactAttempts,
  });

  factory _FollowUpListItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateSafe(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value as String);
      } catch (_) {
        return null;
      }
    }

    return _FollowUpListItem(
      id: json['id'] as String? ?? '',
      babySystemId: json['baby_system_id'] as String? ?? '',
      dueDate: parseDateSafe(json['due_date']),
      status: json['status'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'new',
      daysOverdue: json['days_overdue'] as int? ?? 0,
      contactAttempts: json['contact_attempts'] as int? ?? 0,
    );
  }

  final String id;
  final String babySystemId;
  final DateTime? dueDate;
  final String status;
  final String urgency;
  final int daysOverdue;
  final int contactAttempts;
}
