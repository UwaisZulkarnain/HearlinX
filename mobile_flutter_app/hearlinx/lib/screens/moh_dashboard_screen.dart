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

class MohDashboardScreen extends StatefulWidget {
  const MohDashboardScreen({super.key});

  @override
  State<MohDashboardScreen> createState() => _MohDashboardScreenState();
}

class _MohDashboardScreenState extends State<MohDashboardScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  _NationalSummary _summary = const _NationalSummary();
  DateTime? _lastUpdatedTime;

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

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reports/national-summary'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseErrorMessage(response.body));
      }

      late Map<String, dynamic> payload;
      try {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        if (!mounted) return;
        setState(() => _errorMessage = 'Ralat data dari pelayan.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ralat data dari pelayan.')),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = _NationalSummary.fromJson(payload);
        _lastUpdatedTime = DateTime.now();
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Sambungan lambat. Sila cuba semula.';
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

  Widget _overviewChip(
    String label,
    Object value,
    Color color, {
    required bool isMobile,
  }) {
    IconData getIcon(String label) {
      if (label.contains('Hospital') || label.contains('Rumah')) {
        return Icons.local_hospital_rounded;
      } else if (label.contains('Screening') || label.contains('Saringan')) {
        return Icons.person_search_rounded;
      } else if (label.contains('Pass') || label.contains('Lulus')) {
        return Icons.check_circle_rounded;
      } else if (label.contains('Refer') || label.contains('Rujuk')) {
        return Icons.arrow_forward_rounded;
      } else if (label.contains('LTFU')) {
        return Icons.warning_rounded;
      }
      return Icons.info_rounded;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF18C7A5), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getIcon(label), size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppStyles.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _kpiCards(AppText t) {
    final cards = [
      (
        label: t.hospital,
        value: _summary.totalHospitals,
        color: AppStyles.accent,
      ),
      (
        label: t.totalScreenings,
        value: _summary.totalScreenings,
        color: AppStyles.brand,
      ),
      (label: t.pass, value: _summary.totalPass, color: AppStyles.success),
      (label: t.refer, value: _summary.totalRefer, color: AppStyles.danger),
      (label: t.ltfu, value: _summary.totalLtfu, color: AppStyles.warning),
      (
        label: t.ltfuRate,
        value: '${_summary.ltfuRate.toStringAsFixed(1)}%',
        color: AppStyles.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;

        if (screenWidth < 600) {
          final cardWidth = (availableWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: cardWidth,
                    child: AspectRatio(
                      aspectRatio: screenWidth < 380 ? 1.35 : 1.55,
                      child: _overviewChip(
                        card.label,
                        card.value,
                        card.color,
                        isMobile: true,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        }

        final cardWidth =
            (availableWidth - (12 * (cards.length - 1))) / cards.length;
        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              SizedBox(
                width: cardWidth,
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: _overviewChip(
                    cards[index].label,
                    cards[index].value,
                    cards[index].color,
                    isMobile: false,
                  ),
                ),
              ),
              if (index != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  String _dashboardTitle(AppText t) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) {
      return t.isMs ? 'Papan Pemuka' : 'Dashboard';
    }
    if (width < 600) {
      return t.isMs ? 'Papan Pemuka MoH' : 'MoH Dashboard';
    }
    return t.nationalDashboard;
  }

  Widget _lastUpdatedBanner(AppText t) {
    if (_lastUpdatedTime == null) {
      return const SizedBox.shrink();
    }

    final formattedTime = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(_lastUpdatedTime!.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18C7A5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${t.lastUpdated}: $formattedTime',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalPerformanceSection(AppText t) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            t.hospitalPerformance,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (_summary.hospitals.isEmpty)
            Text(
              t.noNationalData,
              style: const TextStyle(color: AppStyles.textSecondary),
            )
          else
            ..._summary.hospitals.map((hospital) {
              final coverageRate = _summary.totalScreenings > 0
                  ? (hospital.totalScreenings / _summary.totalScreenings) * 100
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.screening}: ${hospital.totalScreenings}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppStyles.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${coverageRate.toStringAsFixed(1)}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF18C7A5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: coverageRate / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF18C7A5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t.refer} ${hospital.totalRefer}  |  ${t.ltfu} ${hospital.totalLtfu} (${hospital.ltfuRate.toStringAsFixed(1)}%)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppStyles.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kpiCards(t),
                    const SizedBox(height: 16),
                    _lastUpdatedBanner(t),
                    const SizedBox(height: 16),
                    _hospitalPerformanceSection(t),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return AppShell(title: _dashboardTitle(t), child: _body());
  }
}

class _NationalSummary {
  const _NationalSummary({
    this.totalHospitals = 0,
    this.totalScreenings = 0,
    this.totalPass = 0,
    this.totalRefer = 0,
    this.totalLtfu = 0,
    this.hospitals = const [],
  });

  factory _NationalSummary.fromJson(Map<String, dynamic> json) {
    return _NationalSummary(
      totalHospitals: json['total_hospitals'] as int? ?? 0,
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalPass: json['total_pass'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
      totalLtfu: json['total_ltfu'] as int? ?? 0,
      hospitals: (json['hospitals'] as List<dynamic>? ?? [])
          .map(
            (item) => _NationalHospital.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int totalHospitals;
  final int totalScreenings;
  final int totalPass;
  final int totalRefer;
  final int totalLtfu;
  final List<_NationalHospital> hospitals;

  double get ltfuRate => totalRefer == 0 ? 0 : (totalLtfu / totalRefer) * 100;
}

class _NationalHospital {
  const _NationalHospital({
    required this.name,
    required this.totalScreenings,
    required this.totalRefer,
    required this.totalLtfu,
  });

  factory _NationalHospital.fromJson(Map<String, dynamic> json) {
    return _NationalHospital(
      name: json['hospital_name'] as String? ?? '',
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
      totalLtfu: json['total_ltfu'] as int? ?? 0,
    );
  }

  final String name;
  final int totalScreenings;
  final int totalRefer;
  final int totalLtfu;

  double get ltfuRate => totalRefer == 0 ? 0 : (totalLtfu / totalRefer) * 100;
}
