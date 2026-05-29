import 'package:flutter/material.dart';

class AppStyles {
  static const brand = Color(0xFF0D6E63);
  static const accent = Color(0xFF17B8A1);
  static const background = Color(0xFFF6FAF9);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF20323B);
  static const textSecondary = Color(0xFF5B6B73);
  static const success = Color(0xFF26D07C);
  static const danger = Color(0xFFE85D75);
  static const warning = Color(0xFFF59E0B);
  static const pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 28);
  static const formPagePadding = EdgeInsets.symmetric(horizontal: 28, vertical: 20);
  static const buttonHeight = 60.0;
  static const buttonRadius = 14.0;
  static const cardRadius = 14.0;

  static const headingStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );
  static const sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );
  static const bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );
  static const labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    height: 1.35,
  );

  static BoxDecoration surfaceCard({Color color = surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: accent.withValues(alpha: 0.65),
      elevation: 0,
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
    );
  }

  static ButtonStyle outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: brand,
      side: const BorderSide(color: brand),
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
    );
  }
}
