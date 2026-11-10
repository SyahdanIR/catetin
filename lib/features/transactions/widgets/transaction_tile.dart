import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/wallet_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryModel.getById(transaction.categoryId);
    final wallet = WalletModel.getById(transaction.walletId);
    final isIncome = transaction.type == TransactionType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: AppBorders.borderWidth,
        ),
        boxShadow: AppShadows.tactileSmall,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category chip, Recurring tag, Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.bgColor,
                  borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 13,
                      color: category.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.ink,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (transaction.isRecurring) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.repeat_rounded,
                        size: 11,
                        color: Color(0xFF7E22CE),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Rutin',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFF7E22CE),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Amount
              Text(
                CurrencyFormatter.format(
                  isIncome ? transaction.amount : -transaction.amount,
                  withSign: true,
                ),
                style: (isIncome
                        ? AppTypography.moneyIncome
                        : AppTypography.moneyExpense)
                    .copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Middle: Title / description
          Text(
            transaction.title,
            style: AppTypography.headingSmall.copyWith(
              fontSize: 15,
            ),
          ),

          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              transaction.notes!,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 10),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 8),

          // Bottom Row: Wallet indicator on left, Edit & Delete links on right
          Row(
            children: [
              Icon(
                wallet.icon,
                size: 14,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 4),
              Text(
                wallet.name,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),

              const Spacer(),

              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(44, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ubah',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),

              if (onDelete != null)
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(44, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Hapus',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
