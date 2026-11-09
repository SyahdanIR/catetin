import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized shadows and borders for Dompetku's tactile design language.
class AppBorders {
  AppBorders._();

  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 22.0;
  static const double radiusFull = 999.0;

  static const double borderWidth = 1.5;
  static const double borderWidthThick = 2.0;

  static final Border solid = Border.all(
    color: AppColors.border,
    width: borderWidth,
  );

  static final Border solidThick = Border.all(
    color: AppColors.border,
    width: borderWidthThick,
  );

  static final Border muted = Border.all(
    color: AppColors.borderLight,
    width: 1.0,
  );
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> tactileStandard = [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(3, 3),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> tactileSmall = [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> tactileLarge = [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> tactilePressed = [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(1, 1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> none = [];
}
