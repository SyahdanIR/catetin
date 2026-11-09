import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/transaction_model.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../transactions/widgets/transaction_tile.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback onViewAllTap;
  final Function(TransactionModel) onEditTransaction;
  final Function(String) onDeleteTransaction;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onViewAllTap,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terkini',
              style: AppTypography.headingSmall,
            ),
            TextButton(
              onPressed: onViewAllTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
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
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const EmptyStateView(
            title: 'Belum Ada Transaksi',
            message: 'Yuk mulai catat pengeluaran dan pemasukan harianmu!',
          )
        else
          ...transactions.map(
            (tx) => TransactionTile(
              transaction: tx,
              onEdit: () => onEditTransaction(tx),
              onDelete: () => onDeleteTransaction(tx.id),
            ),
          ),
      ],
    );
  }
}
