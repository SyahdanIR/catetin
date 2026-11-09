import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/meemo_mascot.dart';
import '../widgets/cashflow_summary_cards.dart';
import '../widgets/category_breakdown_chart.dart';

enum ReportPeriod {
  month,
  quarter,
  year,
  custom,
}

enum ReportTab {
  cashflow,
  portfolio,
}

class ReportsScreen extends StatefulWidget {
  final FinanceRepository repository;

  const ReportsScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.month;
  ReportTab _selectedTab = ReportTab.cashflow;
  final DateTime _currentPeriodDate = DateTime.now();

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan finansial berhasil diekspor (PDF/CSV)!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = widget.repository.getMonthlyIncome(_currentPeriodDate);
    final expense = widget.repository.getMonthlyExpense(_currentPeriodDate);
    final savingRate = widget.repository.getSavingRate(_currentPeriodDate);
    final breakdown =
        widget.repository.getCategoryExpenseBreakdown(_currentPeriodDate);
    final transactions = widget.repository
        .getTransactionsForPeriod(month: _currentPeriodDate);
    final expenseCount =
        transactions.where((t) => t.type == TransactionType.expense).length;
    final avgExpense = expenseCount > 0 ? expense / expenseCount : 0.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan Finansial',
                        style: AppTypography.displayMedium.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Analisis kesehatan keuangan dan arus kas Anda',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const MeemoMascot(size: 38, mood: MeemoMood.happy),
                ],
              ),

              const SizedBox(height: 16),

              // Period & Filter Card
              Container(
                padding: const EdgeInsets.all(14),
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
                  children: [
                    // Period Segment Selector
                    Row(
                      children: [
                        _buildPeriodTab('Bulan', ReportPeriod.month),
                        const SizedBox(width: 6),
                        _buildPeriodTab('Kuartal', ReportPeriod.quarter),
                        const SizedBox(width: 6),
                        _buildPeriodTab('Tahun', ReportPeriod.year),
                        const SizedBox(width: 6),
                        _buildPeriodTab('Kustom', ReportPeriod.custom),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderLight, height: 1),
                    const SizedBox(height: 10),

                    // Date dropdown & Export Button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppBorders.radiusSmall,
                            ),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppDateFormatter.formatMonthYear(
                                  _currentPeriodDate,
                                ),
                                style: AppTypography.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _exportReport,
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusSmall,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(
                                AppBorders.radiusSmall,
                              ),
                              boxShadow: AppShadows.tactileSmall,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.file_download_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ekspor',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Toggle: Arus Kas vs Portofolio
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTab = ReportTab.cashflow),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedTab == ReportTab.cashflow
                                ? AppColors.primaryLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppBorders.radiusSmall,
                            ),
                            border: _selectedTab == ReportTab.cashflow
                                ? Border.all(color: AppColors.border, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            'Arus Kas & Pengeluaran',
                            style: AppTypography.labelMedium.copyWith(
                              color: _selectedTab == ReportTab.cashflow
                                  ? AppColors.primaryDark
                                  : AppColors.inkMuted,
                              fontWeight: _selectedTab == ReportTab.cashflow
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTab = ReportTab.portfolio),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedTab == ReportTab.portfolio
                                ? AppColors.highlightLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppBorders.radiusSmall,
                            ),
                            border: _selectedTab == ReportTab.portfolio
                                ? Border.all(color: AppColors.border, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            'Kekayaan & Dompet',
                            style: AppTypography.labelMedium.copyWith(
                              color: _selectedTab == ReportTab.portfolio
                                  ? AppColors.highlightText
                                  : AppColors.inkMuted,
                              fontWeight: _selectedTab == ReportTab.portfolio
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_selectedTab == ReportTab.cashflow) ...[
                // Three Cashflow Summary Cards
                CashflowSummaryCards(income: income, expense: expense),

                const SizedBox(height: 16),

                // Meemo AI Financial Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4), // Botanical light tint
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                    boxShadow: AppShadows.tactileSmall,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MeemoMascot(
                        size: 44,
                        mood: MeemoMood.saving,
                        showShadow: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan Keuangan Meemo',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              savingRate >= 20
                                  ? 'Bagus sekali! Rasio tabungan Anda bulan ini mencapai ${savingRate.toStringAsFixed(1)}%. Kondisi finansial Anda berada di zona sehat dan siap untuk investasi jangka panjang.'
                                  : 'Pengeluaran bulan ini cukup aktif. Coba pantau kembali alokasi belanja non-pokok agar rasio tabungan mencapai minimal 20%.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Card
                Container(
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
                      Text('Statistik Finansial', style: AppTypography.headingSmall),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Total Catatan Transaksi',
                        '${transactions.length} transaksi',
                      ),
                      const Divider(color: AppColors.borderLight, height: 16),
                      _buildStatRow(
                        'Rata-rata per Pengeluaran',
                        CurrencyFormatter.format(avgExpense),
                      ),
                      const Divider(color: AppColors.borderLight, height: 16),
                      _buildStatRow(
                        'Rasio Tabungan (Saving Rate)',
                        '${savingRate.toStringAsFixed(1)}%',
                        valueColor: savingRate >= 20
                            ? AppColors.incomeDark
                            : AppColors.expenseDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category Spending Breakdown
                CategoryBreakdownChart(
                  breakdown: breakdown,
                  totalExpense: expense,
                ),
              ] else ...[
                // Portfolio & Assets Overview
                Container(
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
                      Text(
                        'Distribusi Aset & Rekening',
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: 12),
                      _buildPortfolioItem(
                        'Dompet Utama (Tunai)',
                        13082900,
                        Icons.account_balance_wallet_rounded,
                        AppColors.primary,
                      ),
                      const Divider(color: AppColors.borderLight, height: 16),
                      _buildPortfolioItem(
                        'Rekening Bank (BCA)',
                        25400000,
                        Icons.account_balance_rounded,
                        AppColors.catTransport,
                      ),
                      const Divider(color: AppColors.borderLight, height: 16),
                      _buildPortfolioItem(
                        'E-Wallet (GoPay & OVO)',
                        850000,
                        Icons.phone_android_rounded,
                        AppColors.catShopping,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, ReportPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
            border: Border.all(
              color: isSelected ? AppColors.border : AppColors.borderLight,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.inkMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioItem(
    String name,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: AppTypography.labelMedium),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
