import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  bool _showAllHistory = false;
  String? _errorMessage;
  String _coordinatorName = '';
  _MonthlySummary _summary = const _MonthlySummary();
  List<_FollowUpItem> _followUps = const [];
  List<_HospitalScreeningItem> _screenings = const [];
  _BenchmarkData _benchmark = const _BenchmarkData();
  _CoverageData _coverage = const _CoverageData();
  List<_WardBreakdownItem> _wards = const [];

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

      final headers = {'Authorization': 'Bearer $token'};
      final screeningsEndpoint = _showAllHistory
          ? '${ApiConfig.baseUrl}/screenings/'
          : '${ApiConfig.baseUrl}/screenings/?today=true';

      // Get coordinator name
      final displayName = await _authService.getDisplayName();

      final responses = await Future.wait<http.Response?>([
        http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/reports/monthly'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse('${ApiConfig.baseUrl}/followups/'), headers: headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse(screeningsEndpoint), headers: headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/reports/benchmark'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
        http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/reports/coverage'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
        http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/reports/ward-breakdown'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
      ]);

      final monthlyResponse = responses[0];
      if (monthlyResponse == null) {
        _finishLoadingWithError(t.noResponseFor(t.monthlyReportLabel));
        return;
      }
      final followUpsResponse = responses[1];
      if (followUpsResponse == null) {
        _finishLoadingWithError(t.noResponseFor(t.followupListLabel));
        return;
      }
      final screeningsResponse = responses[2];
      if (screeningsResponse == null) {
        _finishLoadingWithError(t.noResponseFor(t.todayScreeningsLabel));
        return;
      }
      final benchmarkResponse = responses[3];
      if (benchmarkResponse == null) {
        _finishLoadingWithError(t.noResponseFor(t.benchmarkLabel));
        return;
      }
      final coverageResponse = responses[4];
      if (coverageResponse == null) {
        _finishLoadingWithError(t.noResponseFor(t.coverageRateLabel));
        return;
      }
      final wardBreakdownResponse = responses[5];
      if (wardBreakdownResponse == null) {
        _finishLoadingWithError(t.noResponseFor(t.wardBreakdownLabel));
        return;
      }

      for (final response in responses.whereType<http.Response>()) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'HTTP ${response.statusCode}: ${_parseErrorMessage(response.body)}',
          );
        }
      }

      final summaryJson = _decodeMapResponse(monthlyResponse);
      final followUpJson = _decodeListResponse(followUpsResponse);
      final screeningJson = _decodeListResponse(screeningsResponse);
      final benchmarkJson = _decodeMapResponse(benchmarkResponse);
      final coverageJson = _decodeMapResponse(coverageResponse);
      final wardBreakdownJson = _decodeMapResponse(wardBreakdownResponse);

      if (!mounted) {
        return;
      }

      setState(() {
        _coordinatorName = displayName;
        _summary = _MonthlySummary.fromJson(summaryJson);
        _followUps = followUpJson
            .map((item) => _FollowUpItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _followUps.sort((a, b) {
          final urgencyOrder = {'ltfu': 0, 'red': 1, 'amber': 2, 'new': 3};
          final orderA = urgencyOrder[a.urgency] ?? 99;
          final orderB = urgencyOrder[b.urgency] ?? 99;
          if (orderA != orderB) return orderA.compareTo(orderB);
          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          return 0;
        });
        _screenings = screeningJson
            .map(
              (item) =>
                  _HospitalScreeningItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        _benchmark = _BenchmarkData.fromJson(benchmarkJson);
        _coverage = _CoverageData.fromJson(coverageJson);
        final wardsList = wardBreakdownJson['wards'] as List<dynamic>? ?? [];
        _wards = wardsList
            .map(
              (item) =>
                  _WardBreakdownItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        _isLoading = false;
      });
    } on SocketException {
      _finishLoadingWithError(t.noInternet);
    } on TimeoutException {
      _finishLoadingWithError(t.slowConnection);
    } on FormatException {
      _finishLoadingWithError(t.serverDataError);
    } catch (e) {
      _finishLoadingWithError(e.toString());
    }
  }

  Future<void> _toggleHistory(bool showAll) async {
    final t = context.read<LanguageProvider>().text;

    if (_showAllHistory == showAll) {
      return;
    }

    setState(() {
      _showAllHistory = showAll;
    });

    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(t.sessionExpired);
      }

      final endpoint = showAll
          ? '${ApiConfig.baseUrl}/screenings/'
          : '${ApiConfig.baseUrl}/screenings/?today=true';
      final response = await http
          .get(Uri.parse(endpoint), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseErrorMessage(response.body));
      }

      final screeningJson = _decodeListResponse(response);
      if (!mounted) {
        return;
      }

      setState(() {
        _screenings = screeningJson
            .map(
              (item) =>
                  _HospitalScreeningItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      });
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

  Map<String, dynamic> _decodeMapResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected JSON object.');
  }

  List<dynamic> _decodeListResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected JSON list.');
  }

  void _finishLoadingWithError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  String _parseErrorMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final detail = payload['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    } catch (_) {}
    if (body.trim().isNotEmpty) {
      return body.trim();
    }
    return context.read<LanguageProvider>().text.unknownError;
  }

  Future<void> _updateFollowUpStatus(String id, String status) async {
    await _patchFollowUp(id, {'status': status});
  }

  Future<void> _patchFollowUp(String id, Map<String, dynamic> payload) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(context.read<LanguageProvider>().text.sessionExpired);
      }

      final response = await _apiService.client
          .patch(
            Uri.parse('${_apiService.baseEndpoint}/followups/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseErrorMessage(response.body));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().text.followupStatusUpdated,
          ),
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
      throw Exception(context.read<LanguageProvider>().text.sessionExpired);
    }
    final response = await _apiService.client.get(
      Uri.parse('${_apiService.baseEndpoint}/followups/$id/events'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseErrorMessage(response.body));
    }
    try {
      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .map((item) => _FollowUpEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      throw Exception(context.read<LanguageProvider>().text.serverDataError);
    }
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

  Widget _sectionCard({
    String? title,
    Widget? titleWidget,
    required Widget child,
  }) {
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
          titleWidget ??
              Text(
                title ?? '',
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
    final hasNoDashboardData =
        _summary.totalScreenings == 0 &&
        _summary.totalPass == 0 &&
        _summary.totalRefer == 0 &&
        _summary.totalLtfu == 0 &&
        _followUps.isEmpty &&
        _screenings.isEmpty &&
        _wards.isEmpty;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppStyles.surfaceCard(),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: _loadData,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF18C7A5)),
                      foregroundColor: const Color(0xFF18C7A5),
                    ),
                    child: Text(t.retry),
                  ),
                ],
              ),
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
          if (hasNoDashboardData) ...[
            const SizedBox(height: 18),
            _sectionCard(
              title: t.dashboard,
              child: Text(
                t.dashboardNoDataMessage,
                style: const TextStyle(color: AppStyles.textSecondary),
              ),
            ),
          ],
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
          // Additional Info Row - FIXED OVERFLOW
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: AppStyles.surfaceCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Color(0xFF18C7A5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.lastScreening,
                              style: TextStyle(
                                color: AppStyles.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getLastScreeningTime(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: AppStyles.surfaceCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: Color(0xFF18C7A5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.activeScreeners,
                              style: TextStyle(
                                color: AppStyles.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
          // Coverage Rate Section
          _sectionCard(
            title: t.coverageRateTitle,
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: _coverage.coverageRatePct / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF14B8A6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_coverage.coverageRatePct.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_coverage.totalBabiesScreened} / ${_coverage.totalBabiesRegistered} bayi disaring',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // 1-3-6 KKM Benchmark Section
          _sectionCard(
            title: t.benchmarkTitle,
            child: Column(
              children: [
                // 1 Month Screened
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.screenedBy1Month,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_benchmark.screenedBy1MonthPct.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _benchmark.screenedBy1MonthPct / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _benchmark.screenedBy1MonthPct >= 90
                              ? AppStyles.success
                              : _benchmark.screenedBy1MonthPct >= 70
                              ? AppStyles.warning
                              : AppStyles.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 3 Months Diagnosed
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.diagnosedBy3Months,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_benchmark.diagnosedBy3MonthsPct.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _benchmark.diagnosedBy3MonthsPct / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _benchmark.diagnosedBy3MonthsPct >= 90
                              ? AppStyles.success
                              : _benchmark.diagnosedBy3MonthsPct >= 70
                              ? AppStyles.warning
                              : AppStyles.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.kkmTarget,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Ward Breakdown Section
          _sectionCard(
            title: t.wardBreakdown,
            child: _wards.isEmpty
                ? Text(
                    t.noWardData,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[100],
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            t.wardLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            t.totalCount,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            t.referCount,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            t.ratePercentage,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      rows: _wards.map((ward) {
                        final referRateColor = ward.referRatePct < 10
                            ? AppStyles.success
                            : ward.referRatePct <= 20
                            ? AppStyles.warning
                            : AppStyles.danger;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                ward.ward ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text('${ward.totalScreenings}')),
                            DataCell(Text('${ward.totalRefer}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: referRateColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${ward.referRatePct.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: referRateColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            titleWidget: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.followupQueue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppStyles.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_followUps.length}',
                    style: const TextStyle(
                      color: AppStyles.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            child: _followUps.isEmpty
                ? Text(
                    t.noPendingFollowups,
                    style: const TextStyle(color: AppStyles.textSecondary),
                  )
                : Column(
                    children: [
                      ..._followUps
                          .take(5)
                          .map((item) => _buildCompactFollowUpRow(item, t)),
                      if (_followUps.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed('/coordinator/followups');
                              },
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: Text(
                                '${t.viewAll} (${_followUps.length - 5} ${t.more})',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppStyles.accent,
                                side: const BorderSide(color: AppStyles.accent),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            titleWidget: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _showAllHistory ? t.allScreenings : t.todayScreenings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_showAllHistory) {
                            _toggleHistory(false);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: !_showAllHistory
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.today,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !_showAllHistory
                                  ? AppStyles.textPrimary
                                  : AppStyles.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!_showAllHistory) {
                            _toggleHistory(true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _showAllHistory
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.allHistory,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _showAllHistory
                                  ? AppStyles.textPrimary
                                  : AppStyles.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            child: _screenings.isEmpty
                ? Text(
                    _showAllHistory
                        ? t.noAllScreenings
                        : t.todayScreeningRecorded,
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

  Future<void> _showAppointmentDialog(String id) async {
    final t = context.read<LanguageProvider>().text;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.bookAppointmentTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.appointmentDateLabel),
                  const SizedBox(height: 16),

                  // Date picker button
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppStyles.accent,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppStyles.accent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate == null
                                ? (t.isMs ? 'Pilih tarikh' : 'Pick date')
                                : DateFormat(
                                    'd MMM yyyy',
                                  ).format(selectedDate!),
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Colors.grey[500]
                                  : AppStyles.textPrimary,
                              fontWeight: selectedDate == null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time picker button
                  InkWell(
                    onTap: selectedDate == null
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 9, minute: 0),
                              initialEntryMode: TimePickerEntryMode.input,
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(
                                    context,
                                  ).copyWith(alwaysUse24HourFormat: true),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppStyles.accent,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() => selectedTime = picked);
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedDate == null
                              ? Colors.grey[200]!
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: selectedDate == null ? Colors.grey[50] : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: selectedDate == null
                                ? Colors.grey[300]
                                : AppStyles.accent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedTime == null
                                ? (t.isMs ? 'Pilih masa' : 'Pick time')
                                : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: selectedTime == null
                                  ? (selectedDate == null
                                        ? Colors.grey[300]
                                        : Colors.grey[500])
                                  : AppStyles.textPrimary,
                              fontWeight: selectedTime == null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (selectedDate != null && selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '${DateFormat('d MMM yyyy').format(selectedDate!)} · ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppStyles.accent,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // Show warning if date selected but time not yet picked
                  if (selectedDate != null && selectedTime == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppStyles.danger,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.isMs ? 'Sila pilih masa' : 'Please select time',
                              style: TextStyle(
                                color: AppStyles.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(t.cancel),
                ),
                FilledButton(
                  onPressed: (selectedDate != null && selectedTime != null)
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppStyles.accent,
                  ),
                  child: Text(t.confirmAppointment),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedDate != null && selectedTime != null) {
      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      await _patchFollowUp(id, {
        'status': 'appointment_booked',
        'appointment_date': dateTime.toIso8601String(),
      });
    }
  }

  Future<void> _showEscalationDialog(String id) async {
    final t = context.read<LanguageProvider>().text;
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.escalateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.escalationReasonLabel),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: t.escalationReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppStyles.accent),
            child: Text(t.confirmEscalation),
          ),
        ],
      ),
    );

    if (result == true) {
      await _patchFollowUp(id, {
        'status': 'escalated',
        'notes': controller.text.trim().isEmpty ? null : controller.text.trim(),
      });
    }

    controller.dispose();
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Baby ID card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppStyles.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppStyles.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppStyles.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppStyles.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.babyIdLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppStyles.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.babySystemId,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status section
                        Text(
                          t.statusLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedStatus,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              items:
                                  [
                                    ('pending', t.statusPending),
                                    ('contacted', t.statusContacted),
                                    (
                                      'appointment_booked',
                                      t.statusAppointmentBooked,
                                    ),
                                    ('escalated', t.statusEscalated),
                                    ('completed', t.statusCompleted),
                                    (
                                      'lost_to_followup',
                                      t.statusLostToFollowup,
                                    ),
                                    ('closed', t.statusClosed),
                                  ].map((item) {
                                    final (value, label) = item;
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setModalState(() => selectedStatus = value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Appointment date
                        Text(
                          t.appointmentDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: appointmentController,
                          decoration: InputDecoration(
                            hintText: t.appointmentDateHint,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppStyles.accent,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // LTFU Reason
                        Text(
                          t.ltfuReasonLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            hintText: t.ltfuReasonHint,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppStyles.accent,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        Text(
                          t.notesOptionalLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: t.notesHint,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppStyles.accent,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact attempts badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 18,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${t.contactAttemptsLabel}: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                              Text(
                                '${item.contactAttempts}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Timeline header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.timelineTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppStyles.textPrimary,
                              ),
                            ),
                            if (events.isNotEmpty)
                              Text(
                                '${events.length} ${t.timelineCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppStyles.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (events.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppStyles.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  t.noTimelineEvents,
                                  style: TextStyle(
                                    color: AppStyles.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...events.map((event) {
                            final urgencyColor = switch (event.action) {
                              'created_from_rujuk' => AppStyles.accent,
                              'status_changed' => Colors.blue,
                              'contact_attempt' => Colors.orange,
                              'escalated' => AppStyles.danger,
                              'completed' => AppStyles.success,
                              _ => AppStyles.textSecondary,
                            };

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: urgencyColor,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _translateTimelineAction(
                                            event.action,
                                            t,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'd MMM',
                                        ).format(event.createdAt.toLocal()),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppStyles.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (event.fromStatus != null ||
                                      event.toStatus != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 18),
                                      child: Text(
                                        '${_translateStatus(event.fromStatus ?? '-', t)} ${t.statusTo} ${_translateStatus(event.toStatus ?? '-', t)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppStyles.textSecondary,
                                        ),
                                      ),
                                    ),
                                  if ((event.notes ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 18,
                                        top: 4,
                                      ),
                                      child: Text(
                                        event.notes!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppStyles.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 18),
                                    child: Text(
                                      DateFormat(
                                        'hh:mm a',
                                      ).format(event.createdAt.toLocal()),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppStyles.textSecondary
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 24),

                        // Save button
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
                            style: FilledButton.styleFrom(
                              backgroundColor: AppStyles.accent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              t.saveChanges,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
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

  String _translateTimelineAction(String action, AppText t) {
    return switch (action) {
      'created_from_rujuk' => t.actionCreatedFromRujuk,
      'status_changed' => t.actionStatusChanged,
      'contact_attempt' => t.actionContactAttempt,
      'note_added' => t.actionNoteAdded,
      'appointment_booked' => t.actionAppointmentBooked,
      'escalated' => t.actionEscalated,
      'marked_ltfu' => t.actionMarkedLtfu,
      'completed' => t.actionCompleted,
      _ => action,
    };
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

  (String urgency, String label, Color color, String subtitle) _resolveUrgency(
    _FollowUpItem item,
    AppText t,
  ) {
    final now = DateTime.now();

    // Helper: format date without showing ":00" midnight time
    String _formatAppointmentDate(DateTime date) {
      final hasTime = date.hour != 0 || date.minute != 0;
      final dateFormat = hasTime
          ? (t.isMs ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy, hh:mm a')
          : 'd MMM yyyy';
      return DateFormat(dateFormat, 'en_US').format(date);
    }

    // 1. Appointment-based override (most important)
    if (item.appointmentDate != null) {
      final hoursUntil = item.appointmentDate!.difference(now).inHours;

      if (hoursUntil <= 24 && hoursUntil > 0) {
        return (
          'red',
          t.redRisk,
          AppStyles.danger,
          '${t.appointmentDate}: ${_formatAppointmentDate(item.appointmentDate!)} · ${t.overdue}',
        );
      }
      if (hoursUntil <= 168 && hoursUntil > 0) {
        return (
          'amber',
          t.statusContacted,
          const Color(0xFFEA580C),
          '${t.appointmentDate}: ${_formatAppointmentDate(item.appointmentDate!)} · ${hoursUntil ~/ 24} ${t.dateLabel}',
        );
      }
      if (hoursUntil <= 0) {
        return (
          'red',
          t.redRisk,
          AppStyles.danger,
          '${t.appointmentDate}: ${_formatAppointmentDate(item.appointmentDate!)} · ${t.overdue}',
        );
      }
    }

    // 2. Backend urgency fallback
    return switch (item.urgency) {
      'ltfu' => (
        'ltfu',
        t.ltfu,
        AppStyles.warning,
        item.daysOverdue > 0
            ? '${t.dateLabel} ${item.daysOverdue} ${t.dateLabel}'
            : '${t.dateLabel} ${t.dateLabel}',
      ),
      'red' => (
        'red',
        t.redRisk,
        AppStyles.danger,
        item.daysOverdue > 0
            ? '${t.dateLabel} ${item.daysOverdue} ${t.dateLabel}'
            : '${t.dateLabel} ${t.dateLabel}',
      ),
      'amber' => (
        'amber',
        t.overdue,
        const Color(0xFFEA580C),
        '${t.dueDateLabel}: ${DateFormat('d MMM').format(item.dueDate ?? now)}',
      ),
      _ => (
        'new',
        t.newFollowup,
        AppStyles.accent,
        item.dueDate != null
            ? '${t.dueDateLabel}: ${DateFormat('d MMM').format(item.dueDate!)}'
            : t.noDueDate,
      ),
    };
  }

  Widget _buildCompactFollowUpRow(_FollowUpItem item, AppText t) {
    final (urgency, urgencyLabel, urgencyColor, subtitle) = _resolveUrgency(
      item,
      t,
    );

    final screeningText = item.screeningDate != null
        ? '${t.dateLabel}: ${DateFormat('d MMM').format(item.screeningDate!)}'
        : '';

    final dueText = item.dueDate == null
        ? t.noDueDate
        : DateFormat('d MMM').format(item.dueDate!);

    // Format appointment time for compact display badge
    String? appointmentTimeText;
    Color appointmentTimeColor = AppStyles.accent;
    if (item.appointmentDate != null) {
      final hasTime =
          item.appointmentDate!.hour != 0 || item.appointmentDate!.minute != 0;
      final displayFormat = hasTime
          ? (t.isMs ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy, hh:mm a')
          : 'd MMM yyyy';
      appointmentTimeText = DateFormat(
        displayFormat,
        'en_US',
      ).format(item.appointmentDate!);
      if (item.appointmentDate!.isBefore(DateTime.now())) {
        appointmentTimeColor = AppStyles.danger;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Tap-to-view-details row
          InkWell(
            onTap: () => _showFollowUpDetails(item),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
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
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppStyles.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else ...[
                          Text(
                            '$dueText · $urgencyLabel',
                            style: TextStyle(
                              color: AppStyles.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (screeningText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              screeningText,
                              style: TextStyle(
                                color: AppStyles.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        // Compact appointment time badge
                        if (item.appointmentDate != null &&
                            appointmentTimeText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: appointmentTimeColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 10,
                                    color: appointmentTimeColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    appointmentTimeText,
                                    style: TextStyle(
                                      color: appointmentTimeColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _translateStatus(item.status, t),
                      style: TextStyle(
                        color: urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppStyles.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Quick action buttons -- instant update, no modal
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _miniActionButton(
                  t.markContacted,
                  () => _quickAction(item.id, 'contacted', t.markedAsContacted),
                  Colors.green,
                ),
                _miniActionButton(
                  t.bookAppointment,
                  () => _showAppointmentDialog(item.id),
                  Colors.blue,
                ),
                _miniActionButton(
                  t.escalate,
                  () => _showEscalationDialog(item.id),
                  Colors.orange,
                ),
                _miniActionButton(
                  t.complete,
                  () => _confirmAndQuickAction(
                    item.id,
                    'completed',
                    t.confirmComplete,
                    t.caseCompleted,
                  ),
                  AppStyles.success,
                ),
                _miniActionButton(
                  t.markLtfu,
                  () => _confirmAndQuickAction(
                    item.id,
                    'lost_to_followup',
                    t.confirmMarkLtfu,
                    t.caseMarkedLtfu,
                  ),
                  AppStyles.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniActionButton(String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
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
    required this.screeningDate,
  });

  factory _FollowUpItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateSafe(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value as String);
      } catch (_) {
        return null;
      }
    }

    return _FollowUpItem(
      id: json['id'] as String? ?? '',
      babySystemId: json['baby_system_id'] as String? ?? '',
      dueDate: parseDateSafe(json['due_date']),
      status: json['status'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'new',
      daysOverdue: json['days_overdue'] as int? ?? 0,
      notes: json['notes'] as String?,
      appointmentDate: parseDateSafe(json['appointment_date']),
      ltfuReason: json['ltfu_reason'] as String?,
      contactAttempts: json['contact_attempts'] as int? ?? 0,
      screeningDate: parseDateSafe(
        json['created_at'] ?? json['screening_date'],
      ),
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
  final DateTime? screeningDate;
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
    DateTime createdAtSafe() {
      try {
        return DateTime.parse(json['created_at'] as String);
      } catch (_) {
        return DateTime.now();
      }
    }

    return _FollowUpEvent(
      action: json['action'] as String? ?? '',
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String?,
      notes: json['notes'] as String?,
      createdAt: createdAtSafe(),
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
    DateTime screeningDateSafe() {
      try {
        return DateTime.parse(json['screening_date'] as String);
      } catch (_) {
        return DateTime.now();
      }
    }

    return _HospitalScreeningItem(
      babySystemId: json['baby_system_id'] as String? ?? '',
      earLeft: json['ear_left'] as String? ?? '',
      earRight: json['ear_right'] as String? ?? '',
      screeningDate: screeningDateSafe(),
    );
  }

  final String babySystemId;
  final String earLeft;
  final String earRight;
  final DateTime screeningDate;

  bool get isRefer => earLeft == 'refer' || earRight == 'refer';

  String get resultLabel => isRefer ? 'REFER' : 'PASS';
}

class _BenchmarkData {
  const _BenchmarkData({
    this.screenedBy1MonthPct = 0,
    this.diagnosedBy3MonthsPct = 0,
  });

  factory _BenchmarkData.fromJson(Map<String, dynamic> json) {
    return _BenchmarkData(
      screenedBy1MonthPct:
          (json['screened_by_1_month_pct'] as num?)?.toDouble() ?? 0,
      diagnosedBy3MonthsPct:
          (json['diagnosed_by_3_months_pct'] as num?)?.toDouble() ?? 0,
    );
  }

  final double screenedBy1MonthPct;
  final double diagnosedBy3MonthsPct;
}

class _CoverageData {
  const _CoverageData({
    this.totalBabiesRegistered = 0,
    this.totalBabiesScreened = 0,
    this.coverageRatePct = 0,
  });

  factory _CoverageData.fromJson(Map<String, dynamic> json) {
    return _CoverageData(
      totalBabiesRegistered: json['total_babies_registered'] as int? ?? 0,
      totalBabiesScreened: json['total_babies_screened'] as int? ?? 0,
      coverageRatePct: (json['coverage_rate_pct'] as num?)?.toDouble() ?? 0,
    );
  }

  final int totalBabiesRegistered;
  final int totalBabiesScreened;
  final double coverageRatePct;
}

class _WardBreakdownItem {
  const _WardBreakdownItem({
    this.ward,
    required this.totalScreenings,
    required this.totalRefer,
    required this.referRatePct,
  });

  factory _WardBreakdownItem.fromJson(Map<String, dynamic> json) {
    return _WardBreakdownItem(
      ward: json['ward'] as String?,
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
      referRatePct: (json['refer_rate_pct'] as num?)?.toDouble() ?? 0,
    );
  }

  final String? ward;
  final int totalScreenings;
  final int totalRefer;
  final double referRatePct;
}
