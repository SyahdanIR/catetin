import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';

class CashflowSummaryCards extends StatelessWidget {
  final double income;
  final double expense;

  const CashflowSummaryCards({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final net = income - expense;

    return Column(
      children: [
        Row(
          children: [
            // Income Card
            Expanded(
              child: _buildMetricCard(
                title: 'Pemasukan',
                amount: income,
                bgColor: AppColors.incomeLight,
                textColor: AppColors.incomeDark,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 8),

            // Expense Card
            Expanded(
              child: _buildMetricCard(
                title: 'Pengeluaran',
                amount: expense,
                bgColor: AppColors.expenseLight,
                textColor: AppColors.expenseDark,
                icon: Icons.north_east_rounded,
              ),
            ),
            const SizedBox(width: 8),

            // Net Card
            Expanded(
              child: _buildMetricCard(
                title: 'Selisih Net',
                amount: net,
                bgColor: AppColors.highlightLight,
                textColor: AppColors.highlightText,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Selisih Bersih = Total Pemasukan - Total Pengeluaran',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.inkMuted,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double amount,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
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
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: textColor,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTypography.headingSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
