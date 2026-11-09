import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category_model.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final Map<String, num> breakdown;
  final num totalExpense;

  const CategoryBreakdownChart({
    super.key,
    required this.breakdown,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty || totalExpense <= 0) {
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
        child: Center(
          child: Text(
            'Belum ada pengeluaran pada periode ini',
            style: AppTypography.bodySmall,
          ),
        ),
      );
    }

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alokasi Pengeluaran',
                style: AppTypography.headingSmall,
              ),
              Text(
                '${sortedEntries.length} Kategori',
                style: AppTypography.labelSmall,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Proportional Multi-Segment Progress Bar
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppBorders.radiusSmall - 1),
              child: Row(
                children: sortedEntries.map((entry) {
                  final category = CategoryModel.getById(entry.key);
                  final flex = ((entry.value / totalExpense) * 1000).toInt();
                  return Expanded(
                    flex: flex > 0 ? flex : 1,
                    child: Container(color: category.color),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Itemized Category Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length,
            separatorBuilder: (_, _) => const Divider(
              color: AppColors.borderLight,
              height: 14,
            ),
            itemBuilder: (context, i) {
              final entry = sortedEntries[i];
              final category = CategoryModel.getById(entry.key);
              final percentage = (entry.value / totalExpense) * 100;

              return Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: AppTypography.labelMedium,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    CurrencyFormatter.format(entry.value),
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
