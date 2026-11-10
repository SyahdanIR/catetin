import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/report_models.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class IncomeExpenseChart extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<IncomeExpenseTrendPoint> points;

  const IncomeExpenseChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends State<IncomeExpenseChart> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _defaultSelectedIndex(widget.points);
  }

  @override
  void didUpdateWidget(covariant IncomeExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points.length != widget.points.length ||
        _rangeChanged(oldWidget.points, widget.points)) {
      _selectedIndex = _defaultSelectedIndex(widget.points);
    } else if (_selectedIndex != null && _selectedIndex! >= widget.points.length) {
      _selectedIndex = _defaultSelectedIndex(widget.points);
    }
  }

  bool _rangeChanged(
    List<IncomeExpenseTrendPoint> a,
    List<IncomeExpenseTrendPoint> b,
  ) {
    if (a.isEmpty || b.isEmpty) return a.length != b.length;
    return a.first.startDate != b.first.startDate ||
        a.last.endDate != b.last.endDate;
  }

  int? _defaultSelectedIndex(List<IncomeExpenseTrendPoint> points) {
    if (points.isEmpty) return null;
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].income > 0 || points[i].expense > 0) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyFlow =
        widget.points.any((p) => p.income > 0 || p.expense > 0);

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
          // Header and color legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.headingSmall),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _buildLegendDot('Masuk', AppColors.income),
                  _buildLegendDot('Keluar', AppColors.expense),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!hasAnyFlow || widget.points.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MeemoMascot(
                      size: 40,
                      mood: MeemoMood.thinking,
                      showShadow: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada arus kas pada periode ini',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.inkLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grafik pemasukan dan pengeluaran akan muncul setelah ada transaksi.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            _buildChartContent(),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    int maxVal = 0;
    for (final p in widget.points) {
      maxVal = math.max(maxVal, math.max(p.income, p.expense));
    }
    final safeMax = maxVal > 0 ? maxVal : 1;
    final midVal = (safeMax / 2).round();
    const double plotHeight = 136.0;
    final bool needsHorizontalScroll = widget.points.length > 5;

    final selectedPoint = (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.points.length)
        ? widget.points[_selectedIndex!]
        : widget.points.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-axis ticks
            SizedBox(
              width: 46,
              height: plotHeight + 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      CurrencyFormatter.formatCompact(safeMax),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      CurrencyFormatter.formatCompact(midVal),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 24),
                    child: Text(
                      '0',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bars area with subtle dashed reference gridlines
            Expanded(
              child: needsHorizontalScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: widget.points.length * 52.0,
                        child: _buildPlotStack(
                          plotHeight: plotHeight,
                          safeMax: safeMax,
                          fixedColumnWidth: 52.0,
                        ),
                      ),
                    )
                  : _buildPlotStack(
                      plotHeight: plotHeight,
                      safeMax: safeMax,
                      fixedColumnWidth: null,
                    ),
            ),
          ],
        ),

        if (needsHorizontalScroll) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Geser grafik ke samping untuk melihat semua periode',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.inkMuted,
                fontSize: 10,
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Selected Bucket Detail Strip
        _buildSelectedDetailStrip(selectedPoint),
      ],
    );
  }

  Widget _buildPlotStack({
    required double plotHeight,
    required int safeMax,
    required double? fixedColumnWidth,
  }) {
    return Stack(
      children: [
        // Subtle horizontal baseline + mid/top guides behind bars
        SizedBox(
          height: plotHeight,
          width: fixedColumnWidth != null
              ? fixedColumnWidth * widget.points.length
              : double.infinity,
          child: CustomPaint(
            painter: _GridLinesPainter(),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < widget.points.length; i++)
              if (fixedColumnWidth != null)
                SizedBox(
                  width: fixedColumnWidth,
                  child: _buildBarColumn(i, plotHeight, safeMax),
                )
              else
                Expanded(
                  child: _buildBarColumn(i, plotHeight, safeMax),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarColumn(int index, double plotHeight, int safeMax) {
    final point = widget.points[index];
    final isSelected = _selectedIndex == index;
    final double incomeHeight = point.income <= 0
        ? 0.0
        : math.max(4.0, (point.income / safeMax) * (plotHeight - 8));
    final double expenseHeight = point.expense <= 0
        ? 0.0
        : math.max(4.0, (point.expense / safeMax) * (plotHeight - 8));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        focusColor: AppColors.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: plotHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildSingleBar(
                        height: incomeHeight,
                        color: AppColors.income,
                      ),
                      const SizedBox(width: 4),
                      _buildSingleBar(
                        height: expenseHeight,
                        color: AppColors.expense,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      point.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected ? AppColors.ink : AppColors.inkMuted,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleBar({
    required double height,
    required Color color,
  }) {
    if (height <= 0) {
      return Container(
        width: 12,
        height: 2,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
    );
  }

  Widget _buildSelectedDetailStrip(IncomeExpenseTrendPoint point) {
    final net = point.netCashFlow;
    final isNegative = net < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  point.fullLabel,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isNegative
                      ? AppColors.expenseLight
                      : AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Text(
                  'Net ${CurrencyFormatter.format(net, withSign: true)}',
                  style: AppTypography.labelSmall.copyWith(
                    color: isNegative
                        ? AppColors.expenseDark
                        : AppColors.incomeDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                'Masuk: ${CurrencyFormatter.format(point.income)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.incomeDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Keluar: ${CurrencyFormatter.format(point.expense)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.expenseDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.inkLight),
        ),
      ],
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    final basePaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), guidePaint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
