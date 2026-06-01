import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/baby.dart';
import '../models/screening.dart';
import '../providers/language_provider.dart';
import '../services/offline_service.dart';
import '../ui/app_styles.dart';

class ScreeningEntryScreen extends StatefulWidget {
  const ScreeningEntryScreen({super.key});

  @override
  State<ScreeningEntryScreen> createState() => _ScreeningEntryScreenState();
}

class _ScreeningEntryScreenState extends State<ScreeningEntryScreen> {
  static const _primaryColor = Color(0xFF17B8A1);
  static const _successColor = Color(0xFF26D07C);
  static const _warningColor = Color(0xFFE63946);
  static const _backgroundColor = Color(0xFFF8F9FA);
  static const _textColor = Color(0xFF2C3E50);
  static const _darkPrimaryColor = Color(0xFF0D6E63);

  final _storage = const FlutterSecureStorage();
  final _offlineService = OfflineService();
  final _notesController = TextEditingController();
  final _manualIdController = TextEditingController();

  Baby? _selectedBaby;
  String _screeningType = 'TEOAE';
  String? _earLeftResult;
  String? _earRightResult;
  bool _isLoading = false;
  bool _showQrScanner = false;
  bool _showManualEntry = false;

  @override
  void dispose() {
    _notesController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchBaby(String systemId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi telah tamat. Sila log masuk semula.'),
            ),
          );
        }
        return;
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/babies/$systemId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Bayi tidak dijumpai'),
            backgroundColor: _warningColor,
          ),
        );
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final babyData = jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _selectedBaby = Baby(
              id: babyData['id'] as String? ?? '',
              systemId: babyData['system_id'] as String? ?? '',
              hospitalId: babyData['hospital_id'] as String? ?? '',
              ward: babyData['ward'] as String? ?? 'N/A',
            );
          });
        } on FormatException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ralat data dari pelayan.'),
                backgroundColor: _warningColor,
              ),
            );
          }
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $errorMessage'),
            backgroundColor: _warningColor,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sambungan lambat. Sila cuba semula.'),
            backgroundColor: _warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat rangkaian: $e'),
            backgroundColor: _warningColor,
          ),
        );
      }
    }
  }

  Future<void> _handleQrCode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      return;
    }

    final barcode = barcodes.first;
    final systemId = barcode.rawValue;

    if (systemId == null || systemId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR code tidak sah')));
      }
      return;
    }

    setState(() {
      _showQrScanner = false;
    });

    await _fetchBaby(systemId);
  }

  Future<void> _handleManualEntry() async {
    final systemId = _manualIdController.text.trim();
    if (systemId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sila masukkan ID Bayi')));
      return;
    }

    setState(() {
      _showManualEntry = false;
    });

    _manualIdController.clear();
    await _fetchBaby(systemId);
  }

  String _mapEarResultToBackend(String result) {
    switch (result.toUpperCase()) {
      case 'LULUS':
      case 'PASS':
        return 'pass';
      case 'RUJUK':
      case 'REFER':
        return 'refer';
      default:
        return result.toLowerCase();
    }
  }

  bool _isConnectivityError(Object error) {
    return error is SocketException || error is http.ClientException;
  }

  Screening _currentScreening() {
    return Screening(
      babyId: _selectedBaby!.id,
      screeningType: _screeningType,
      earLeft: _mapEarResultToBackend(_earLeftResult!),
      earRight: _mapEarResultToBackend(_earRightResult!),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
  }

  void _clearScreeningForm() {
    _selectedBaby = null;
    _screeningType = 'TEOAE';
    _earLeftResult = null;
    _earRightResult = null;
    _manualIdController.clear();
    _notesController.clear();
    _showQrScanner = false;
    _showManualEntry = false;
    _isLoading = false;
  }

  Future<void> _submitScreening() async {
    if (_selectedBaby == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sila pilih bayi')));
      return;
    }

    if (_earLeftResult == null || _earRightResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila pilih hasil untuk kedua-dua telinga'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi telah tamat. Sila log masuk semula.'),
            ),
          );
        }
        return;
      }

      final screening = _currentScreening();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/screenings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'baby_id': screening.babyId,
          'screening_type': screening.screeningType,
          'ear_left': screening.earLeft,
          'ear_right': screening.earRight,
          'notes': screening.notes,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saringan berjaya disimpan \u2713'),
            backgroundColor: _successColor,
          ),
        );

        setState(() {
          _clearScreeningForm();
        });
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $errorMessage'),
            backgroundColor: _warningColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_isConnectivityError(e) && _selectedBaby != null) {
          await _offlineService.savePendingScreening(_currentScreening());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tiada sambungan. Saringan disimpan untuk sync.'),
              backgroundColor: _primaryColor,
            ),
          );
          setState(() {
            _clearScreeningForm();
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat rangkaian: $e'),
            backgroundColor: _warningColor,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail is String) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final firstError = detail[0] as Map<String, dynamic>;
        return firstError['msg'] as String? ?? 'Ralat tidak diketahui';
      }
    } catch (_) {}
    return 'Ralat tidak diketahui';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final languageProvider = context.watch<LanguageProvider>();
    final t = languageProvider.text;
    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(now);

    return AppBar(
      backgroundColor: _darkPrimaryColor,
      elevation: 0,
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.newScreening,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            formattedDate,
            style: const TextStyle(
              color: Color(0xFFB3E5DB),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_showQrScanner) {
      return _buildQrScannerView();
    }

    if (_showManualEntry) {
      return _buildManualEntryView();
    }

    return SingleChildScrollView(
      padding: AppStyles.formPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baby ID Entry Section
          _buildBabyIdSection(),
          const SizedBox(height: 36),

          // Baby Info Display
          if (_selectedBaby != null) ...[
            _buildBabyInfoCard(),
            const SizedBox(height: 36),
          ],

          // Ear Results Section
          if (_selectedBaby != null) ...[
            _buildScreeningTypeField(),
            const SizedBox(height: 36),

            _buildEarResultsSection(),
            const SizedBox(height: 36),

            // Notes Field
            _buildNotesField(),
            const SizedBox(height: 36),

            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildQrScannerView() {
    return Stack(
      children: [
        MobileScanner(onDetect: _handleQrCode),
        const Positioned.fill(child: IgnorePointer(child: _ScannerOverlay())),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() {
                _showQrScanner = false;
              });
            },
            child: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntryView() {
    final t = context.watch<LanguageProvider>().text;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit, color: _darkPrimaryColor, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              t.typeBabyId,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.enterBabyToContinue,
              style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _manualIdController,
                decoration: InputDecoration(
                  hintText: '${t.babyId} (B001)',
                  hintStyle: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.badge, color: _primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppStyles.buttonHeight,
                child: ElevatedButton(
                  onPressed: _handleManualEntry,
                  style: AppStyles.primaryButtonStyle(),
                  child: Text(
                    t.continueText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppStyles.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showManualEntry = false;
                    _manualIdController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.buttonRadius),
                    side: BorderSide(
                      color: _primaryColor.withOpacity(0.7),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  t.cancel,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyIdSection() {
    final t = context.watch<LanguageProvider>().text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // QR Scan Button with enhanced styling
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: AppStyles.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showQrScanner = true;
                });
              },
              style: AppStyles.primaryButtonStyle(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    t.scanQR,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Manual Entry Link with better styling
        GestureDetector(
          onTap: () {
            setState(() {
              _showManualEntry = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            child: Text(
              t.manualEntry,
              style: const TextStyle(
                color: _primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBabyInfoCard() {
    final t = context.watch<LanguageProvider>().text;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.child_care,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                t.babyInfo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.babyId,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _selectedBaby!.systemId,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _darkPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.ward,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedBaby!.ward,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _darkPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screening Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _screeningType,
            items: const [
              DropdownMenuItem(value: 'TEOAE', child: Text('TEOAE')),
              DropdownMenuItem(value: 'AABR', child: Text('AABR')),
              DropdownMenuItem(value: 'ABR', child: Text('ABR')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _screeningType = value;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarResultsSection() {
    final t = context.watch<LanguageProvider>().text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Ear Section
        _buildEarSection(t.leftEar, 'LEFT'),
        const SizedBox(height: 24),

        // Right Ear Section
        _buildEarSection(t.rightEar, 'RIGHT'),
      ],
    );
  }

  Widget _buildEarSection(String label, String side) {
    final isLeft = side == 'LEFT';
    final selectedResult = isLeft ? _earLeftResult : _earRightResult;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEarButton(
                  label: 'LULUS',
                  isSelected: selectedResult == 'pass',
                  color: _successColor,
                  onPressed: () {
                    setState(() {
                      if (isLeft) {
                        _earLeftResult = 'pass';
                      } else {
                        _earRightResult = 'pass';
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEarButton(
                  label: 'RUJUK',
                  isSelected: selectedResult == 'refer',
                  color: _warningColor,
                  onPressed: () {
                    setState(() {
                      if (isLeft) {
                        _earLeftResult = 'refer';
                      } else {
                        _earRightResult = 'refer';
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final t = context.watch<LanguageProvider>().text;
    final displayLabel = label == 'LULUS' ? t.pass : t.refer;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppStyles.buttonHeight),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.buttonRadius),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF999999),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    final t = context.watch<LanguageProvider>().text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.notes,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _notesController,
            maxLength: 100,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t.notes,
              hintStyle: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              counterStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final t = context.watch<LanguageProvider>().text;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStyles.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: _successColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppStyles.buttonHeight,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitScreening,
          style: AppStyles.primaryButtonStyle(),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  t.submit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.68;
        final squareTop = (constraints.maxHeight - scanSize) / 2 - 48;
        final squareLeft = (constraints.maxWidth - scanSize) / 2;
        final labelTop = squareTop + scanSize + 28;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.black54),
                  ),
                  Positioned(
                    left: squareLeft,
                    top: squareTop,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: const BoxDecoration(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: squareLeft,
              top: squareTop,
              child: CustomPaint(
                size: Size(scanSize, scanSize),
                painter: _ScannerFramePainter(),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: labelTop,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  t.pointCameraQr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const accentColor = Color(0xFF17B8A1);
    const borderLength = 28.0;
    const strokeWidth = 5.0;
    const radius = 18.0;

    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final frameRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    canvas.drawRRect(frameRect, framePaint);

    final path = Path()
      ..moveTo(0, borderLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(borderLength, 0)
      ..moveTo(size.width - borderLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, borderLength)
      ..moveTo(size.width, size.height - borderLength)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(size.width - borderLength, size.height)
      ..moveTo(borderLength, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, size.height - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
