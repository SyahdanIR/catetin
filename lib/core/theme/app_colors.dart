import 'package:flutter/material.dart';

/// Centralized color palette for Catetin.
///
/// Designed with an original "Modern Tactile Slate & Botanical Teal" identity.
/// Avoids generic AI gradients and provides WCAG AA compliant contrast ratios.
class AppColors {
  AppColors._();

  // Background & Surface
  static const Color background = Color(0xFFF7F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F4F1);
  static const Color surfaceWarm = Color(0xFFFDFBF7);

  // Deep Ink / Border / Shadow (Neo-Tactile foundation)
  static const Color ink = Color(0xFF0F172A); // Slate 900
  static const Color inkLight = Color(0xFF334155); // Slate 700
  static const Color inkMuted = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFF0F172A); // Crisp 1.5px border
  static const Color borderLight = Color(0xFFCBD5E1); // Muted border
  static const Color shadow = Color(0xFF0F172A); // Offset shadow

  // Brand Primaries
  static const Color primary = Color(0xFF0D9488); // Botanical Teal
  static const Color primaryDark = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFFCCFBF1); // Soft Teal Tint
  static const Color primaryText = Color(0xFF115E59); // High-contrast Teal text

  // Brand Secondary & Accent
  static const Color accent = Color(0xFFEA580C); // Warm Tangerine
  static const Color accentLight = Color(0xFFFFEDD5); // Soft Tangerine Tint
  static const Color accentText = Color(0xFF9A3412); // High-contrast Tangerine text

  static const Color highlight = Color(0xFFEAB308); // Sunlit Amber
  static const Color highlightLight = Color(0xFFFEF9C3); // Soft Amber Tint
  static const Color highlightText = Color(0xFF854D0E); // High-contrast Amber text

  // Financial Indicators
  static const Color income = Color(0xFF16A34A); // Positive Green
  static const Color incomeLight = Color(0xFFDCFCE7); // Positive Green Tint
  static const Color incomeDark = Color(0xFF14532D); // Deep Green Text

  static const Color expense = Color(0xFFE11D48); // Negative Crimson Rose
  static const Color expenseLight = Color(0xFFFFE4E6); // Negative Crimson Tint
  static const Color expenseDark = Color(0xFF881337); // Deep Crimson Text

  // Category Accents (Harmonized, high-contrast)
  static const Color catFood = Color(0xFFF97316);
  static const Color catFoodBg = Color(0xFFFFEDD5);

  static const Color catTransport = Color(0xFF0284C7);
  static const Color catTransportBg = Color(0xFFE0F2FE);

  static const Color catShopping = Color(0xFF9333EA);
  static const Color catShoppingBg = Color(0xFFF3E8FF);

  static const Color catEntertainment = Color(0xFFD946EF);
  static const Color catEntertainmentBg = Color(0xFFFAE8FF);

  static const Color catBills = Color(0xFFEAB308);
  static const Color catBillsBg = Color(0xFFFEF9C3);

  static const Color catSalary = Color(0xFF16A34A);
  static const Color catSalaryBg = Color(0xFFDCFCE7);

  static const Color catInvestment = Color(0xFF0D9488);
  static const Color catInvestmentBg = Color(0xFFCCFBF1);

  static const Color catHealth = Color(0xFFEF4444);
  static const Color catHealthBg = Color(0xFFFEE2E2);
}
