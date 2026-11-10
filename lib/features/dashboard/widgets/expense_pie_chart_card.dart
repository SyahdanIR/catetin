import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class ExpensePieChartCard extends StatelessWidget {
  final String title;
  final String walletName;
  final String periodLabel;
  final Map<String, int> breakdown;
  final String emptyTitle;
  final String emptyActionHint;
  final Widget? headerTrailing;
  final void Function(CategoryModel category, int amount, double percentage)?
      onCategoryTap;
  final CategoryModel Function(String id)? categoryResolver;

  const ExpensePieChartCard({
    super.key,
    required this.title,
    required this.walletName,
    required this.periodLabel,
    required this.breakdown,
    required this.emptyTitle,
    required this.emptyActionHint,
    this.headerTrailing,
    this.onCategoryTap,
    this.categoryResolver,
  });

  static const double _chartDiameter = 124.0;

  @override
  Widget build(BuildContext context) {
    final resolveCategory = categoryResolver ?? CategoryModel.getById;
    final sortedSlices = breakdown.entries
        .where((entry) => entry.value > 0)
        .map((entry) => MapEntry(resolveCategory(entry.key), entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalExpense = sortedSlices.fold<int>(0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: AppBorders.borderWidth,
        ),
        boxShadow: AppShadows.tactileSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and optional period selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headingSmall,
                ),
              ),
              if (headerTrailing != null) ...[
                const SizedBox(width: 8),
                headerTrailing!,
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Active wallet badge and period total
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                  border: Border.all(color: AppColors.borderLight, width: 1.0),
                ),
                child: Text(
                  walletName,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.inkLight,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                totalExpense > 0
                    ? '$periodLabel (${CurrencyFormatter.format(totalExpense)})'
                    : periodLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (sortedSlices.isEmpty || totalExpense <= 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    const MeemoMascot(
                      size: 42,
                      mood: MeemoMood.saving,
                      showShadow: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyTitle,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.inkLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emptyActionHint,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapUp: onCategoryTap == null
                      ? null
                      : (details) => _handleChartTap(
                            details.localPosition,
                            sortedSlices,
                            totalExpense,
                          ),
                  child: SizedBox(
                    width: _chartDiameter,
                    height: _chartDiameter,
                    child: CustomPaint(
                      painter: _ExpensePiePainter(
                        slices: sortedSlices,
                        totalAmount: totalExpense,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedSlices.map((entry) {
                      final category = entry.key;
                      final amount = entry.value;
                      final percentage = (amount / totalExpense) * 100;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCategoryTap == null
                              ? null
                              : () => onCategoryTap!(
                                    category,
                                    amount,
                                    percentage,
                                  ),
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusSmall,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: category.color,
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category.name,
                                          style: AppTypography.labelMedium
                                              .copyWith(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}% · ${CurrencyFormatter.format(amount)}',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: AppColors.inkMuted,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (onCategoryTap != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Ketuk kategori untuk lihat detail',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _handleChartTap(
    Offset localPosition,
    List<MapEntry<CategoryModel, int>> slices,
    int totalAmount,
  ) {
    final radius = _chartDiameter / 2;
    final dx = localPosition.dx - radius;
    final dy = localPosition.dy - radius;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance > radius || totalAmount <= 0) return;

    // Normalize clockwise angle starting from 12 o'clock (-pi / 2)
    final tapAngle = (math.atan2(dy, dx) + math.pi / 2) % (2 * math.pi);

    double cumulativeAngle = 0.0;
    for (final entry in slices) {
      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi;
      if (tapAngle <= cumulativeAngle + sweepAngle) {
        final percentage = (entry.value / totalAmount) * 100;
        onCategoryTap?.call(entry.key, entry.value, percentage);
        return;
      }
      cumulativeAngle += sweepAngle;
    }
  }
}

class _ExpensePiePainter extends CustomPainter {
  final List<MapEntry<CategoryModel, int>> slices;
  final int totalAmount;

  _ExpensePiePainter({
    required this.slices,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty || totalAmount <= 0) return;

    const strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    if (slices.length == 1) {
      final fillPaint = Paint()
        ..color = slices.first.key.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, borderPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.value / totalAmount) * 2 * math.pi;
      final fillPaint = Paint()
        ..color = slice.key.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, fillPaint);
      startAngle += sweepAngle;
    }

    // Tactile ink outlines separating adjacent slices and framing the circle
    startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.value / totalAmount) * 2 * math.pi;
      final edgeEnd = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      canvas.drawLine(center, edgeEnd, borderPaint);
      startAngle += sweepAngle;
    }
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ExpensePiePainter oldDelegate) {
    return oldDelegate.totalAmount != totalAmount || oldDelegate.slices != slices;
  }
}
