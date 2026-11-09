import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';

class TactileChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? activeColor;
  final Color? activeTextColor;

  const TactileChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.activeColor,
    this.activeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? (activeColor ?? AppColors.ink)
        : AppColors.surface;
    final textColor = isSelected
        ? (activeTextColor ?? Colors.white)
        : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44), // R-03 tap target
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
            border: Border.all(
              color: AppColors.border,
              width: AppBorders.borderWidth,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
