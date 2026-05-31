import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';

class _HospitalOption {
  static final Map<String, String> _hospitalShortNames = {
    'HKL001': 'Hospital KL',
    'HPJ001': 'Hospital Putrajaya',
    'HSB001': 'Hospital Sungai Buloh',
  };

  const _HospitalOption({required this.name, required this.code});

  factory _HospitalOption.fromJson(Map<String, dynamic> json) {
    return _HospitalOption(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  final String name;
  final String code;

  /// Get short hospital code by removing trailing digits (HKL001 → HKL)
  String get shortCode {
    final stripped = code.replaceFirst(RegExp(r'\d+$'), '');
    return stripped.isNotEmpty ? stripped : code;
  }

  /// Get display label in short format: "Hospital KL (HKL)"
  String get label {
    final displayName = _hospitalShortNames[code] ?? name;
    return '$displayName ($shortCode)';
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _backgroundColor = Color(0xFF1A3C40);
  static const _accentColor = Color(0xFF18C7A5);
  static const _fieldBorderColor = Color(0xFFD9E8EB);

  final _formKey = GlobalKey<FormState>();
  final _staffIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _authService = AuthService();

  List<_HospitalOption> _hospitals = const [];
  String? _selectedHospitalCode;
  bool _isFetchingHospitals = true;
  bool _isLoading = false;
  String? _hospitalError;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hintText, {bool isDropdown = false}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF92A5AB), fontSize: 16),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      prefixIcon: isDropdown
          ? const Icon(
              Icons.local_hospital_rounded,
              color: _accentColor,
              size: 22,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accentColor, width: 2),
      ),
    );
  }

  Widget _languageToggle(String label, String lang) {
    final languageProvider = context.watch<LanguageProvider>();
    final isSelected = languageProvider.lang == lang;

    return Expanded(
      child: SizedBox(
        height: 36,
        child: TextButton(
          onPressed: () => languageProvider.setLang(lang),
          style: TextButton.styleFrom(
            backgroundColor: isSelected ? _accentColor : Colors.white,
            foregroundColor: isSelected ? Colors.white : _backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isFetchingHospitals = true;
      _hospitalError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/hospitals/'),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal memuatkan hospital');
      }

      final payload = jsonDecode(response.body) as List<dynamic>;
      final hospitals = payload
          .map((item) => _HospitalOption.fromJson(item as Map<String, dynamic>))
          .where(
            (hospital) => hospital.name.isNotEmpty && hospital.code.isNotEmpty,
          )
          .toList();

      setState(() {
        _hospitals = hospitals;
        _selectedHospitalCode = hospitals.isEmpty ? null : hospitals.first.code;
        _isFetchingHospitals = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hospitalError = e.toString().replaceFirst('Exception: ', '');
        _isFetchingHospitals = false;
      });
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.login(
      hospitalCode: _selectedHospitalCode!,
      staffId: _staffIdController.text.trim(),
      pin: _pinController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageProvider>().text.invalidCreds),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().text;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.headphones_rounded,
                            color: _accentColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFF9AF3E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'DengarTrack',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.appSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t.welcome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t.hospital,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isFetchingHospitals)
                          const SizedBox(
                            height: 56,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _accentColor,
                                ),
                              ),
                            ),
                          )
                        else if (_hospitalError != null)
                          Text(
                            _hospitalError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _selectedHospitalCode,
                            decoration: _inputDecoration(
                              t.selectHospital,
                              isDropdown: true,
                            ),
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: _hospitals
                                .map(
                                  (hospital) => DropdownMenuItem<String>(
                                    value: hospital.code,
                                    child: Text(
                                      hospital.label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return t.selectHospital;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedHospitalCode = value;
                              });
                            },
                          ),
                        const SizedBox(height: 26),
                        Text(
                          t.staffId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _staffIdController,
                          decoration: _inputDecoration(t.enterStaffId),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t.enterStaffId;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 26),
                        Text(
                          t.pin,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 3,
                          ),
                          decoration: _inputDecoration('••••••'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t.enterPin;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            _languageToggle('BM', 'ms'),
                            const SizedBox(width: 18),
                            _languageToggle('EN', 'en'),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accentColor, const Color(0xFF0D9E8A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ||
                                      _isFetchingHospitals ||
                                      _selectedHospitalCode == null
                                  ? null
                                  : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      t.signIn,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.forgotPin)),
                            );
                          },
                          child: Text(
                            t.forgotPin,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              decoration: TextDecoration.underline,
                              decorationColor: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
