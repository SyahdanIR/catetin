import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'meemo_mascot.dart';
import 'tactile_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final MeemoMood mood;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.mood = MeemoMood.thinking,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MeemoMascot(size: 80, mood: mood),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            TactileButton(
              text: actionLabel!,
              onPressed: onAction,
              variant: TactileButtonVariant.primary,
              icon: Icons.add_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
