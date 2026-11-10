import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback onViewAllTap;
  final Function(TransactionModel) onEditTransaction;
  final Function(String) onDeleteTransaction;
  final CategoryModel Function(String id)? categoryResolver;
  final WalletModel Function(String id)? walletResolver;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onViewAllTap,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    this.categoryResolver,
    this.walletResolver,
  });

  void _showTransactionDetailSheet(BuildContext context, TransactionModel tx) {
    final category = (categoryResolver ?? CategoryModel.getById)(tx.categoryId);
    final wallet = (walletResolver ?? WalletModel.getById)(tx.walletId);
    final isIncome = tx.type == TransactionType.income;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorders.radiusLarge),
        ),
        side: BorderSide(
          color: AppColors.border,
          width: AppBorders.borderWidth,
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: category.bgColor,
                      borderRadius:
                          BorderRadius.circular(AppBorders.radiusSmall),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Icon(category.icon, color: category.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: AppTypography.headingSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${category.name} · ${wallet.name}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                  border: Border.all(color: AppColors.borderLight, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        isIncome ? tx.amount : -tx.amount,
                        withSign: true,
                      ),
                      style: (isIncome
                              ? AppTypography.moneyIncome
                              : AppTypography.moneyExpense)
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateFormatter.formatGroupDate(tx.date),
                      style: AppTypography.bodySmall,
                    ),
                    if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        tx.notes!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDeleteTransaction(tx.id);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(
                          color: AppColors.expense,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorders.radiusMedium),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onEditTransaction(tx);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorders.radiusMedium),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Ubah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = transactions.take(3).toList();

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
          // Header inside the single card box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Transaksi Terkini',
                  style: AppTypography.headingSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onViewAllTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.borderLight, height: 12),

          if (visibleTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    const MeemoMascot(
                      size: 40,
                      mood: MeemoMood.thinking,
                      showShadow: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum Ada Transaksi',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yuk mulai catat pengeluaran dan pemasukan harianmu!',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: visibleTransactions.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppColors.borderLight,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final tx = visibleTransactions[index];
                final category =
                    (categoryResolver ?? CategoryModel.getById)(tx.categoryId);
                final isIncome = tx.type == TransactionType.income;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showTransactionDetailSheet(context, tx),
                    borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: category.bgColor,
                                borderRadius: BorderRadius.circular(
                                  AppBorders.radiusSmall,
                                ),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.0,
                                ),
                              ),
                              child: Icon(
                                category.icon,
                                size: 18,
                                color: category.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tx.title,
                                    style: AppTypography.labelLarge.copyWith(
                                      fontSize: 13.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${category.name} · ${AppDateFormatter.formatShortDate(tx.date)}',
                                    style: AppTypography.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(
                                isIncome ? tx.amount : -tx.amount,
                                withSign: true,
                              ),
                              style: (isIncome
                                      ? AppTypography.moneyIncome
                                      : AppTypography.moneyExpense)
                                  .copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
