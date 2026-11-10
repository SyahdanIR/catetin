import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/report_models.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final Map<String, num> breakdown;
  final num totalExpense;
  final List<CategoryBreakdownItem>? items;
  final CategoryModel Function(String id)? categoryResolver;

  const CategoryBreakdownChart({
    super.key,
    required this.breakdown,
    required this.totalExpense,
    this.items,
    this.categoryResolver,
  });

  @override
  Widget build(BuildContext context) {
    final resolveCategory = categoryResolver ?? CategoryModel.getById;
    final List<CategoryBreakdownItem> resolvedItems;

    if (items != null) {
      resolvedItems = items!.where((item) => item.amount > 0).toList();
    } else if (totalExpense > 0 && breakdown.isNotEmpty) {
      final sortedEntries = breakdown.entries
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      resolvedItems = sortedEntries.map((entry) {
        final amount = entry.value.round();
        return CategoryBreakdownItem(
          categoryId: entry.key,
          category: resolveCategory(entry.key),
          amount: amount,
          percentage: (amount / totalExpense) * 100,
          transactionCount: 0,
        );
      }).toList();
    } else {
      resolvedItems = const [];
    }

    if (resolvedItems.isEmpty || totalExpense <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const MeemoMascot(
              size: 40,
              mood: MeemoMood.thinking,
              showShadow: false,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada pengeluaran pada periode ini',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.inkLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Catat pengeluaran untuk melihat pembagian belanja per kategori.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
            children: [
              Expanded(
                child: Text(
                  'Alokasi Pengeluaran',
                  style: AppTypography.headingSmall,
                ),
              ),
              Text(
                '${resolvedItems.length} Kategori',
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
                children: resolvedItems.map((item) {
                  final flex = ((item.amount / totalExpense) * 1000).round();
                  return Expanded(
                    flex: flex > 0 ? flex : 1,
                    child: Container(color: item.category.color),
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
            itemCount: resolvedItems.length,
            separatorBuilder: (_, _) => const Divider(
              color: AppColors.borderLight,
              height: 14,
            ),
            itemBuilder: (context, i) {
              final item = resolvedItems[i];
              return Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.category.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category.name,
                          style: AppTypography.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.transactionCount > 0)
                          Text(
                            '${item.transactionCount} transaksi · ${item.percentage.toStringAsFixed(1)}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            '${item.percentage.toStringAsFixed(1)}% dari total pengeluaran',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        CurrencyFormatter.format(item.amount),
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                      ),
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
