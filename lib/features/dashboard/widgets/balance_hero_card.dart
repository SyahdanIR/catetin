import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class BalanceHeroCard extends StatefulWidget {
  final num totalBalance;
  final num monthlyIncome;
  final num monthlyExpense;
  final String selectedWalletName;
  final VoidCallback onWalletTap;
  final VoidCallback onDetailsTap;

  const BalanceHeroCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.selectedWalletName = 'Semua Dompet',
    required this.onWalletTap,
    required this.onDetailsTap,
  });

  @override
  State<BalanceHeroCard> createState() => _BalanceHeroCardState();
}

class _BalanceHeroCardState extends State<BalanceHeroCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppBorders.radiusLarge),
        border: Border.all(
          color: AppColors.border,
          width: AppBorders.borderWidthThick,
        ),
        boxShadow: AppShadows.tactileStandard,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet selector pill and visibility toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onWalletTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.selectedWalletName,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                icon: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.ink,
                  size: 22,
                ),
                tooltip: _isBalanceVisible ? 'Sembunyikan Saldo' : 'Tampilkan Saldo',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Balance & Mascot
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saldo Anda',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isBalanceVisible
                            ? CurrencyFormatter.format(widget.totalBalance)
                            : 'Rp ••••••••',
                        style: AppTypography.moneyHero.copyWith(
                          color: AppColors.ink,
                          fontSize: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const MeemoMascot(
                size: 60,
                mood: MeemoMood.saving,
                showShadow: true,
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Income & Expense Breakdown Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.incomeLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Icon(
                          Icons.south_west_rounded,
                          size: 14,
                          color: AppColors.incomeDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemasukan',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _isBalanceVisible
                                    ? CurrencyFormatter.formatCompact(widget.monthlyIncome)
                                    : '••••',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.incomeDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.expenseLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Icon(
                          Icons.north_east_rounded,
                          size: 14,
                          color: AppColors.expenseDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengeluaran',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _isBalanceVisible
                                    ? CurrencyFormatter.formatCompact(widget.monthlyExpense)
                                    : '••••',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.expenseDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Shortcut to Financial Reports
          InkWell(
            onTap: widget.onDetailsTap,
            borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Buka Laporan Finansial',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
