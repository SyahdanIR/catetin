import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class MeemoInsightCard extends StatelessWidget {
  final VoidCallback onActionTap;
  final String badgeLabel;
  final String message;

  const MeemoInsightCard({
    super.key,
    required this.onActionTap,
    this.badgeLabel = 'Info',
    this.message =
        'Catat pemasukan dan pengeluaranmu untuk melihat ringkasan bulan ini.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.highlightLight,
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: AppBorders.borderWidth,
        ),
        boxShadow: AppShadows.tactileSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const MeemoMascot(
            size: 46,
            mood: MeemoMood.thinking,
            showShadow: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Pesan Meemo Hari Ini',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.highlightText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onActionTap,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 22,
            ),
            tooltip: 'Lihat Tips Selengkapnya',
          ),
        ],
      ),
    );
  }
}
