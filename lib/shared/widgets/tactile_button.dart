import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';

enum TactileButtonVariant {
  primary,
  secondary,
  accent,
  danger,
  highlight,
}

class TactileButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final double height;
  final EdgeInsetsGeometry padding;

  const TactileButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.height = 48.0, // Ensures >= 44px minimum tap target (R-03)
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  Color _getBackgroundColor() {
    if (widget.onPressed == null) return AppColors.surfaceMuted;
    switch (widget.variant) {
      case TactileButtonVariant.primary:
        return AppColors.primary;
      case TactileButtonVariant.secondary:
        return AppColors.surface;
      case TactileButtonVariant.accent:
        return AppColors.accent;
      case TactileButtonVariant.danger:
        return AppColors.expense;
      case TactileButtonVariant.highlight:
        return AppColors.highlight;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null) return AppColors.inkMuted;
    switch (widget.variant) {
      case TactileButtonVariant.primary:
      case TactileButtonVariant.accent:
      case TactileButtonVariant.danger:
        return Colors.white;
      case TactileButtonVariant.secondary:
      case TactileButtonVariant.highlight:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final shadowOffset = (_isPressed && isEnabled) ? 1.0 : 3.0;
    final translationOffset = (_isPressed && isEnabled) ? 2.0 : 0.0;

    final child = Transform.translate(
      offset: Offset(translationOffset, translationOffset),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onPressed,
        child: Container(
          height: widget.height,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
            border: Border.all(
              color: isEnabled ? AppColors.border : AppColors.borderLight,
              width: AppBorders.borderWidth,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(shadowOffset, shadowOffset),
                      blurRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: _getTextColor(),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: AppTypography.labelLarge.copyWith(
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}
