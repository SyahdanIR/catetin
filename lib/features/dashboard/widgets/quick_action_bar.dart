import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../data/models/transaction_model.dart';

class QuickActionBar extends StatelessWidget {
  final Function(TransactionType) onQuickAdd;

  const QuickActionBar({
    super.key,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catat Cepat',
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TactileCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                borderRadius: AppBorders.radiusMedium,
                onTap: () => onQuickAdd(TransactionType.income),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.incomeLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.south_west_rounded,
                        size: 16,
                        color: AppColors.incomeDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Pemasukan',
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TactileCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                borderRadius: AppBorders.radiusMedium,
                onTap: () => onQuickAdd(TransactionType.expense),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.expenseLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.north_east_rounded,
                        size: 16,
                        color: AppColors.expenseDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Pengeluaran',
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
