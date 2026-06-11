import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/coordinator_dashboard_screen.dart';
import 'screens/failed_syncs_screen.dart';
import 'screens/followup_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/moh_dashboard_screen.dart';
import 'screens/screening_entry_screen.dart';
import 'screens/shift_summary_screen.dart';
import 'screens/unhs_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API config with smart URL detection
  await ApiConfig.initialize();

  // Pre-load language before runApp to ensure Malay is set on cold start
  final languageProvider = LanguageProvider();
  await languageProvider.loadSavedLocale();

  // Shorebird: silently check for and download patches on startup
  try {
    final shorebird = ShorebirdCodePush();
    final isUpdateAvailable = await shorebird.isNewPatchAvailableForDownload();
    if (isUpdateAvailable) {
      await shorebird.downloadUpdateIfAvailable();

      // Track patch application for login screen banner
      final prefs = await SharedPreferences.getInstance();
      final currentPatch = await shorebird.currentPatchNumber();
      final previousPatch = prefs.getInt('last_seen_patch');

      if (currentPatch != null && currentPatch != previousPatch) {
        await prefs.setInt('last_seen_patch', currentPatch);
        await prefs.setBool('patch_just_applied', true);
      }
    }
  } catch (_) {
    // Shorebird not available in debug mode or on first install — ignore silently
  }

  runApp(HearLinxApp(languageProvider: languageProvider));
}

class HearLinxApp extends StatelessWidget {
  const HearLinxApp({super.key, required this.languageProvider});

  final LanguageProvider languageProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'DengarTrack',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ms')],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0D7C8A),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const HomeScreen(),
              '/coordinator-dashboard': (_) =>
                  const CoordinatorDashboardScreen(),
              '/coordinator/followups': (_) => const FollowUpListScreen(),
              '/unhs-dashboard': (_) => const UnhsDashboardScreen(),
              '/moh-dashboard': (_) => const MohDashboardScreen(),
              '/screening-entry': (_) => const ScreeningEntryScreen(),
              '/shift-summary': (_) => const ShiftSummaryScreen(),
              '/failed-syncs': (_) => const FailedSyncsScreen(),
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
