import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/coordinator_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/moh_dashboard_screen.dart';
import 'screens/screening_entry_screen.dart';
import 'screens/shift_summary_screen.dart';
import 'screens/unhs_dashboard_screen.dart';

void main() {
  runApp(const HearLinxApp());
}

class HearLinxApp extends StatelessWidget {
  const HearLinxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider()..loadSavedLocale(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'HearLinX',
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
            ),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const HomeScreen(),
              '/coordinator-dashboard': (_) =>
                  const CoordinatorDashboardScreen(),
              '/unhs-dashboard': (_) => const UnhsDashboardScreen(),
              '/moh-dashboard': (_) => const MohDashboardScreen(),
              '/screening-entry': (_) => const ScreeningEntryScreen(),
              '/shift-summary': (_) => const ShiftSummaryScreen(),
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
