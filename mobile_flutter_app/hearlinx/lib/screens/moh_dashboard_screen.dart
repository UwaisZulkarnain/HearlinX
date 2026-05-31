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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reports/national-summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseErrorMessage(response.body));
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) {
        return;
      }

      setState(() {
        _summary = _NationalSummary.fromJson(payload);
        _lastUpdatedTime = DateTime.now();
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

  Widget _overviewChip(String label, int value, Color color) {
    IconData getIcon(String label) {
      if (label.contains('Hospital') || label.contains('Rumah')) {
        return Icons.local_hospital_rounded;
      } else if (label.contains('Screening') || label.contains('Saringan')) {
        return Icons.person_search_rounded;
      } else if (label.contains('Pass') || label.contains('Lulus')) {
        return Icons.check_circle_rounded;
      } else if (label.contains('Refer') || label.contains('Rujuk')) {
        return Icons.arrow_forward_rounded;
      }
      return Icons.info_rounded;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 28,
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
          Row(
            children: [
              _overviewChip(
                t.hospital,
                _summary.totalHospitals,
                AppStyles.accent,
              ),
              const SizedBox(width: 12),
              _overviewChip(
                t.totalScreenings,
                _summary.totalScreenings,
                AppStyles.brand,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _overviewChip(t.pass, _summary.totalPass, AppStyles.success),
              const SizedBox(width: 12),
              _overviewChip(t.refer, _summary.totalRefer, AppStyles.danger),
            ],
          ),
          const SizedBox(height: 18),
          // Last Updated
          if (_lastUpdatedTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF18C7A5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${t.lastUpdated}: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lastUpdatedTime!.toLocal())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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
                  t.hospitalPerformance,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
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
                        ? (hospital.totalScreenings /
                                  _summary.totalScreenings) *
                              100
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hospital.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${t.screening}: ${hospital.totalScreenings}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppStyles.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${coverageRate.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF18C7A5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 6),
                          Text(
                            '${t.refer} ${hospital.totalRefer}',
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return AppShell(title: t.nationalDashboard, child: _body());
  }
}

class _NationalSummary {
  const _NationalSummary({
    this.totalHospitals = 0,
    this.totalScreenings = 0,
    this.totalPass = 0,
    this.totalRefer = 0,
    this.hospitals = const [],
  });

  factory _NationalSummary.fromJson(Map<String, dynamic> json) {
    return _NationalSummary(
      totalHospitals: json['total_hospitals'] as int? ?? 0,
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalPass: json['total_pass'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
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
  final List<_NationalHospital> hospitals;
}

class _NationalHospital {
  const _NationalHospital({
    required this.name,
    required this.totalScreenings,
    required this.totalRefer,
  });

  factory _NationalHospital.fromJson(Map<String, dynamic> json) {
    return _NationalHospital(
      name: json['hospital_name'] as String? ?? '',
      totalScreenings: json['total_screenings'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
    );
  }

  final String name;
  final int totalScreenings;
  final int totalRefer;
}
