import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../ui/app_styles.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.child,
    this.showBackToHome = true,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget child;
  final bool showBackToHome;
  final List<Widget> actions;

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final t = languageProvider.text;

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: AppStyles.brand,
        elevation: 0,
        leading: showBackToHome
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/home', (route) => false);
                },
              )
            : null,
        title: Text(
          title,
          maxLines: 2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        actions: [
          ...actions,
          TextButton(
            onPressed: languageProvider.toggleLang,
            child: Text(
              languageProvider.lang == 'en' ? 'BM' : 'EN',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: t.logout,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: child,
    );
  }
}
