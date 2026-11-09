import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// Distinctive card component with solid border and crisp offset shadow.
class TactileCard extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double shadowOffset;
  final bool enablePressFeedback;

  const TactileCard({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderRadius = AppBorders.radiusMedium,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.shadowOffset = 3.0,
    this.enablePressFeedback = true,
  });

  @override
  State<TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<TactileCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOffset = (_isPressed && widget.enablePressFeedback)
        ? 1.0
        : widget.shadowOffset;
    final translationOffset = (_isPressed && widget.enablePressFeedback)
        ? widget.shadowOffset - 1.0
        : 0.0;

    return Container(
      margin: widget.margin,
      child: Transform.translate(
        offset: Offset(translationOffset, translationOffset),
        child: GestureDetector(
          onTapDown: widget.onTap != null && widget.enablePressFeedback
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.onTap != null && widget.enablePressFeedback
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.onTap != null && widget.enablePressFeedback
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.borderColor,
                width: AppBorders.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(effectiveOffset, effectiveOffset),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
