import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Colours and decorations taken from the Home page, shared by feature screens.
class AppUi {
  /// Home page background.
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3F1FF), Color(0xFFFFFFFF)],
  );

  /// Home hero cards.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF06b6d4)],
  );

  /// Bottom navigation's active button.
  static const accentGradient = LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF3b82f6)]);

  static const accent = Color(0xFF0ea5e9);
  static const ink = Color(0xFF0F172A);
  static const softBlue = Color(0xFFF3F8FF);

  /// Background of icon tiles on Profile list rows.
  static const iconTile = Color(0xFFE3F1FF);

  /// Same shadow as Profile list rows.
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
  ];

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );
}

/// Text styles used on Home and Profile, so feature screens read the same.
/// Font family comes from the app theme (Roboto).
class AppText {
  /// App bar titles (Profile app bar: 18 / w600).
  static const screenTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText);

  /// Section headings ("Health & Wellness" on Home: 18 / bold).
  static const sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText);

  /// Card and list-row titles (Profile row value: 15 / bold; a touch lighter for long titles).
  static const cardTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText, height: 1.3);

  /// Secondary line under a title, e.g. company name.
  static const subtitle = TextStyle(fontSize: 14, color: AppColors.secondaryText);

  /// Paragraph text.
  static const body = TextStyle(fontSize: 14, color: AppColors.primaryText, height: 1.5);

  /// Small labels (Profile row label: 12).
  static const label = TextStyle(fontSize: 12, color: AppColors.secondaryText);

  /// Emphasised value, e.g. salary.
  static const value = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText);

  /// Links and actions ("See All" on Home).
  static const link = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBrand);

  /// Chips and pills.
  static const chip = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryBrand);

  /// Tiny badges (Home badges: 11 / bold).
  static const badge = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

  /// Button text.
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
}
