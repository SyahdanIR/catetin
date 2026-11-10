import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum MeemoMood {
  happy,
  thinking,
  scanning,
  saving,
}

/// Catetin's assistant and mascot: "Meemo" the Pocket Vault Sprite.
///
/// Drawn entirely with Flutter CustomPainter vectors.
/// Crisp, lightweight, scalable, and independent of external image assets.
class MeemoMascot extends StatelessWidget {
  final double size;
  final MeemoMood mood;
  final bool showShadow;

  const MeemoMascot({
    super.key,
    this.size = 54.0,
    this.mood = MeemoMood.happy,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MeemoPainter(mood: mood, showShadow: showShadow),
      ),
    );
  }
}

class _MeemoPainter extends CustomPainter {
  final MeemoMood mood;
  final bool showShadow;

  _MeemoPainter({required this.mood, required this.showShadow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final inkPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill;

    final bodyPaint = Paint()
      ..color = const Color(0xFFF0FDF4) // Soft mint white body
      ..style = PaintingStyle.fill;

    final cheekPaint = Paint()
      ..color = const Color(0xFFFCA5A5) // Soft coral blush
      ..style = PaintingStyle.fill;

    final coinPaint = Paint()
      ..color = AppColors.highlight
      ..style = PaintingStyle.fill;

    // Body dimensions
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.72,
        height: h * 0.68,
      ),
      Radius.circular(w * 0.28),
    );

    // Hard offset shadow
    if (showShadow) {
      final shadowRect = bodyRect.shift(Offset(w * 0.04, h * 0.04));
      canvas.drawRRect(shadowRect, shadowPaint);
    }

    // Body fill & outline
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, inkPaint);

    // Vault coin slot on head
    final slotRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.24),
        width: w * 0.22,
        height: h * 0.08,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(slotRect, coinPaint);
    canvas.drawRRect(slotRect, inkPaint);

    // Cheeks
    canvas.drawCircle(Offset(w * 0.28, h * 0.56), w * 0.06, cheekPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.56), w * 0.06, cheekPaint);

    // Eyes and mouth based on mood
    switch (mood) {
      case MeemoMood.happy:
        // Curved happy closed eyes (arcs)
        final leftEyePath = Path()
          ..moveTo(w * 0.32, h * 0.48)
          ..quadraticBezierTo(w * 0.38, h * 0.42, w * 0.44, h * 0.48);
        final rightEyePath = Path()
          ..moveTo(w * 0.56, h * 0.48)
          ..quadraticBezierTo(w * 0.62, h * 0.42, w * 0.68, h * 0.48);
        canvas.drawPath(leftEyePath, inkPaint);
        canvas.drawPath(rightEyePath, inkPaint);

        // Smile
        final smilePath = Path()
          ..moveTo(w * 0.44, h * 0.56)
          ..quadraticBezierTo(w * 0.5, h * 0.64, w * 0.56, h * 0.56);
        canvas.drawPath(smilePath, inkPaint);
        break;

      case MeemoMood.thinking:
        // One open inquisitive eye, one wink
        canvas.drawCircle(
          Offset(w * 0.38, h * 0.46),
          w * 0.05,
          Paint()..color = AppColors.ink,
        );
        final winkPath = Path()
          ..moveTo(w * 0.56, h * 0.46)
          ..quadraticBezierTo(w * 0.62, h * 0.40, w * 0.68, h * 0.46);
        canvas.drawPath(winkPath, inkPaint);

        // Thoughtful curved mouth
        final mouthPath = Path()
          ..moveTo(w * 0.46, h * 0.58)
          ..quadraticBezierTo(w * 0.54, h * 0.56, w * 0.58, h * 0.62);
        canvas.drawPath(mouthPath, inkPaint);
        break;

      case MeemoMood.scanning:
        // Visor scan line across eyes
        final visorRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.46),
            width: w * 0.48,
            height: h * 0.14,
          ),
          Radius.circular(w * 0.06),
        );
        canvas.drawRRect(visorRect, Paint()..color = AppColors.primaryLight);
        canvas.drawRRect(visorRect, inkPaint);

        // Concentric scan reticle
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.46),
          w * 0.04,
          Paint()..color = AppColors.primaryDark,
        );

        // Focused smile
        final focusedMouth = Path()
          ..moveTo(w * 0.45, h * 0.60)
          ..lineTo(w * 0.55, h * 0.60);
        canvas.drawPath(focusedMouth, inkPaint);
        break;

      case MeemoMood.saving:
        // Stars in eyes
        canvas.drawCircle(
          Offset(w * 0.38, h * 0.46),
          w * 0.04,
          Paint()..color = AppColors.ink,
        );
        canvas.drawCircle(
          Offset(w * 0.62, h * 0.46),
          w * 0.04,
          Paint()..color = AppColors.ink,
        );
        // Big open joyful mouth
        final joyPath = Path()
          ..moveTo(w * 0.42, h * 0.54)
          ..quadraticBezierTo(w * 0.50, h * 0.68, w * 0.58, h * 0.54)
          ..close();
        canvas.drawPath(joyPath, Paint()..color = const Color(0xFFF43F5E));
        canvas.drawPath(joyPath, inkPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MeemoPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.showShadow != showShadow;
}
