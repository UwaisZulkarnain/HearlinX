import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../ui/app_styles.dart';

class ShiftSummaryScreen extends StatefulWidget {
  const ShiftSummaryScreen({super.key});

  @override
  State<ShiftSummaryScreen> createState() => _ShiftSummaryScreenState();
}

class _ShiftSummaryScreenState extends State<ShiftSummaryScreen> {
  static const _accentColor = Color(0xFF17B8A1);
  static const _backgroundColor = Color(0xFFF6FAF9);
  static const _dangerColor = Color(0xFFE85D75);
  static const _successColor = Color(0xFF26D07C);

  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _errorMessage;
  _ShiftSummaryData _summary = const _ShiftSummaryData();
  List<_ScreeningListItem> _screenings = const [];

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
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi telah tamat. Sila log masuk semula.');
      }

      final headers = {'Authorization': 'Bearer $token'};
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/screenings/shift-summary/today'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/screenings/?today=true'),
          headers: headers,
        ),
      ]);

      final summaryResponse = responses[0];
      final listResponse = responses[1];

      if (summaryResponse.statusCode < 200 ||
          summaryResponse.statusCode >= 300) {
        throw Exception(_parseErrorMessage(summaryResponse.body));
      }

      if (listResponse.statusCode < 200 || listResponse.statusCode >= 300) {
        throw Exception(_parseErrorMessage(listResponse.body));
      }

      final summaryJson =
          jsonDecode(summaryResponse.body) as Map<String, dynamic>;
      final listJson = jsonDecode(listResponse.body) as List<dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = _ShiftSummaryData.fromJson(summaryJson);
        _screenings = listJson
            .map(
              (item) =>
                  _ScreeningListItem.fromJson(item as Map<String, dynamic>),
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

  String _parseErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    } catch (_) {}
    return 'Ralat tidak diketahui';
  }

  String _maskSystemId(String systemId) {
    if (systemId.isEmpty) {
      return '****';
    }
    final last4 = systemId.length > 4
        ? systemId.substring(systemId.length - 4)
        : systemId;
    return '****$last4';
  }

  String _getMotivationalMessage() {
    final messages = [
      'Kerja hebat hari ini! 💪',
      'Setiap saringan menyelamatkan masa depan bayi.',
      'Terima kasih atas dedikasi anda!',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  String _badgeLabel(_ScreeningListItem item) {
    final t = context.read<LanguageProvider>().text;

    if (item.earLeft == 'refer' || item.earRight == 'refer') {
      return t.refer;
    }
    return t.pass;
  }

  Color _badgeColor(_ScreeningListItem item) {
    if (item.earLeft == 'refer' || item.earRight == 'refer') {
      return _dangerColor;
    }
    return _successColor;
  }

  Widget _buildMetricCard(String label, int value, Color color) {
    final gradientColors = {
      _accentColor: const [Color(0xFFB2F1DF), Color(0xFFE0F9F6)],
      _successColor: const [Color(0xFFC6F6D5), Color(0xFFF0FDF4)],
      _dangerColor: const [Color(0xFFFECACA), Color(0xFFFEF2F2)],
    };

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors[color] ?? [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF20323B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B6B73),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreeningRow(_ScreeningListItem item) {
    final badgeLabel = _badgeLabel(item);
    final badgeColor = _badgeColor(item);
    final timeText = DateFormat('hh:mm a').format(item.screeningDate.toLocal());
    final leftBorderColor = item.earLeft == 'refer' || item.earRight == 'refer'
        ? _dangerColor
        : _successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: leftBorderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _maskSystemId(item.babySystemId),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20323B),
                    letterSpacing: 0.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF5B6B73),
                height: 1.5,
              ),
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
          Row(
            children: [
              _buildMetricCard(
                'Disaring Hari Ini',
                _summary.totalScreened,
                _accentColor,
              ),
              const SizedBox(width: 12),
              _buildMetricCard('Lulus', _summary.totalPass, _successColor),
              const SizedBox(width: 12),
              _buildMetricCard('Rujuk', _summary.totalRefer, _dangerColor),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF18C7A5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _getMotivationalMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            t.todayScreenings,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20323B),
            ),
          ),
          const SizedBox(height: 14),
          if (_screenings.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: Color(0xFF18C7A5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noTodayScreenings,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7C85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beristirahat dan nikmati hari anda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._screenings.map(_buildScreeningRow),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final t = languageProvider.text;

    return Scaffold(
      backgroundColor: _backgroundColor,
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
        leading: IconButton(
          tooltip: t.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
        actions: [
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
        title: Text(
          t.myShiftSummary,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}

class _ShiftSummaryData {
  const _ShiftSummaryData({
    this.totalScreened = 0,
    this.totalPass = 0,
    this.totalRefer = 0,
  });

  factory _ShiftSummaryData.fromJson(Map<String, dynamic> json) {
    return _ShiftSummaryData(
      totalScreened: json['total_screened'] as int? ?? 0,
      totalPass: json['total_pass'] as int? ?? 0,
      totalRefer: json['total_refer'] as int? ?? 0,
    );
  }

  final int totalScreened;
  final int totalPass;
  final int totalRefer;
}

class _ScreeningListItem {
  const _ScreeningListItem({
    required this.babySystemId,
    required this.earLeft,
    required this.earRight,
    required this.screeningDate,
  });

  factory _ScreeningListItem.fromJson(Map<String, dynamic> json) {
    return _ScreeningListItem(
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
}
