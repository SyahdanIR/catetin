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
  final bool isLoading;
  final double height;
  final EdgeInsetsGeometry padding;

  const TactileButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 48.0, // Ensures >= 44px minimum tap target (R-03)
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  bool get _isInteractive => widget.onPressed != null && !widget.isLoading;

  Color _getBackgroundColor() {
    if (widget.onPressed == null && !widget.isLoading) {
      return AppColors.surfaceMuted;
    }
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
    if (widget.onPressed == null && !widget.isLoading) {
      return AppColors.inkMuted;
    }
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
    final isEnabled = _isInteractive;
    final hasVisualFill = widget.onPressed != null || widget.isLoading;
    final shadowOffset = (_isPressed && isEnabled) ? 1.0 : 3.0;
    final translationOffset = (_isPressed && isEnabled) ? 2.0 : 0.0;

    final child = Transform.translate(
      offset: Offset(translationOffset, translationOffset),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: Container(
          height: widget.height,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
            border: Border.all(
              color: hasVisualFill ? AppColors.border : AppColors.borderLight,
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
              if (widget.isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: _getTextColor(),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    style: AppTypography.labelLarge.copyWith(
                      color: _getTextColor(),
                    ),
                  ),
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
