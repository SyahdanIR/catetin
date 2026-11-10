import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/meemo_mascot.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/expense_pie_chart_card.dart';
import '../widgets/quick_action_bar.dart';
import '../widgets/meemo_insight_card.dart';
import '../widgets/recent_transactions_section.dart';

enum ExpenseCategoryPeriod {
  month,
  year,
  all,
}

class DashboardScreen extends StatefulWidget {
  final FinanceRepository repository;
  final Function(int) onNavigateTab;
  final Function(TransactionType) onQuickAdd;
  final Function(TransactionModel) onEditTransaction;

  const DashboardScreen({
    super.key,
    required this.repository,
    required this.onNavigateTab,
    required this.onQuickAdd,
    required this.onEditTransaction,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ExpenseCategoryPeriod _selectedCategoryPeriod = ExpenseCategoryPeriod.month;

  ({String badgeLabel, String message}) _insightCardCopy(
    MonthlyInsightSummary insight,
  ) {
    if (!insight.hasAnyData) {
      return (
        badgeLabel: 'Info',
        message:
            'Belum ada transaksi bulan ini. Catat pemasukan dan pengeluaranmu untuk melihat ringkasan.',
      );
    }
    if (insight.monthlyIncome == 0) {
      final topCat = insight.topExpenseCategory?.name ?? 'Pengeluaran';
      return (
        badgeLabel: 'Ringkasan',
        message:
            'Pengeluaran bulan ini ${CurrencyFormatter.format(insight.monthlyExpense)}, terbesar di $topCat.',
      );
    }
    final rate = insight.savingRatePercent ?? 0;
    if (rate >= 0) {
      final topCat = insight.topExpenseCategory;
      final detail = topCat != null
          ? ' Pengeluaran terbesar: ${topCat.name}.'
          : ' Belum ada pengeluaran bulan ini.';
      return (
        badgeLabel: 'Hemat ${rate.toStringAsFixed(0)}%',
        message:
            'Selisih kas bulan ini ${CurrencyFormatter.format(insight.netBalance)}.$detail',
      );
    }
    return (
      badgeLabel: 'Defisit',
      message:
          'Pengeluaran melebihi pemasukan ${CurrencyFormatter.format(-insight.netBalance)} bulan ini.',
    );
  }

  void _showInsightDialog(
    BuildContext context,
    MonthlyInsightSummary insight,
    String walletName,
  ) {
    final String heading;
    final String bodyText;
    final String tipText;

    if (!insight.hasAnyData) {
      heading = 'Data Bulan Ini Belum Cukup';
      bodyText =
          'Belum ada transaksi tercatat pada $walletName untuk bulan ini. Catat pemasukan dan pengeluaranmu terlebih dahulu agar Meemo dapat menghitung ringkasan dan rasio tabungan.';
      tipText =
          'Saran Meemo: Mulai dengan mencatat transaksi harian secara rutin agar arus kas lebih mudah dipantau.';
    } else if (insight.monthlyIncome == 0) {
      heading = 'Ringkasan Pengeluaran Bulan Ini';
      final topName = insight.topExpenseCategory?.name ?? 'Lainnya';
      bodyText =
          'Total pengeluaran pada $walletName bulan ini sebesar ${CurrencyFormatter.format(insight.monthlyExpense)}, terbesar pada kategori $topName (${CurrencyFormatter.format(insight.topExpenseAmount)}). Pemasukan bulan ini belum tercatat.';
      tipText =
          'Saran Meemo: Catat pemasukan bulan ini untuk mengetahui rasio tabungan dari penghasilanmu.';
    } else {
      heading = 'Rasio Tabungan Bulan Ini';
      final rate = insight.savingRatePercent ?? 0;
      final topPart = insight.topExpenseCategory != null
          ? ' Pengeluaran terbesar ada di kategori ${insight.topExpenseCategory!.name} (${CurrencyFormatter.format(insight.topExpenseAmount)}).'
          : ' Belum ada pengeluaran tercatat bulan ini.';
      if (insight.netBalance >= 0) {
        bodyText =
            'Pemasukan ${CurrencyFormatter.format(insight.monthlyIncome)} dengan pengeluaran ${CurrencyFormatter.format(insight.monthlyExpense)} (rasio tabungan ${rate.toStringAsFixed(1)}%).$topPart';
        tipText =
            'Saran Meemo: Arus kas bulan ini surplus ${CurrencyFormatter.format(insight.netBalance)}. Pertahankan kebiasaan mencatat setiap transaksi.';
      } else {
        bodyText =
            'Pengeluaran (${CurrencyFormatter.format(insight.monthlyExpense)}) melebihi pemasukan (${CurrencyFormatter.format(insight.monthlyIncome)}) sebesar ${CurrencyFormatter.format(-insight.netBalance)}.$topPart';
        tipText =
            'Saran Meemo: Tinjau ulang pengeluaran pada kategori terbesarmu agar arus kas kembali positif.';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusLarge),
          side: const BorderSide(
            color: AppColors.border,
            width: AppBorders.borderWidth,
          ),
        ),
        title: Row(
          children: [
            const MeemoMascot(size: 38, mood: MeemoMood.happy),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Insight Catetin', style: AppTypography.headingSmall),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: AppTypography.labelLarge.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            Text(bodyText, style: AppTypography.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.highlightLight,
                borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Text(
                tipText,
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: AppTypography.labelLarge.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String transactionId) {
    final messenger = ScaffoldMessenger.of(context);
    var isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.radiusLarge),
            side: const BorderSide(
              color: AppColors.border,
              width: AppBorders.borderWidth,
            ),
          ),
          title: Text('Hapus Transaksi?', style: AppTypography.headingSmall),
          content: Text(
            'Transaksi ini akan dihapus dari catatan keuangan Anda.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: Text('Batal', style: AppTypography.labelMedium),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                ),
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        await widget.repository.deleteTransaction(transactionId);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        messenger
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil dihapus'),
                            ),
                          );
                      } catch (_) {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        messenger
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.expense,
                              content: Text('Gagal menghapus transaksi.'),
                            ),
                          );
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Hapus'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletPicker(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Tampilan Dompet', style: AppTypography.headingSmall),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.all_inbox_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Semua Dompet (Total)',
                  style: AppTypography.labelLarge,
                ),
                trailing: widget.repository.selectedWalletId == 'all'
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  widget.repository.setSelectedWallet('all');
                  Navigator.pop(ctx);
                },
              ),
              const Divider(color: AppColors.borderLight, height: 1),
              ...widget.repository.wallets.map((wallet) {
                final isSelected =
                    widget.repository.selectedWalletId == wallet.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(wallet.icon, color: AppColors.ink, size: 20),
                  ),
                  title: Text(wallet.name, style: AppTypography.labelLarge),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    widget.repository.setSelectedWallet(wallet.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _periodShortLabel(ExpenseCategoryPeriod period) {
    switch (period) {
      case ExpenseCategoryPeriod.month:
        return 'Bulan Ini';
      case ExpenseCategoryPeriod.year:
        return '1 Tahun';
      case ExpenseCategoryPeriod.all:
        return 'Semua';
    }
  }

  String _periodFullLabel(ExpenseCategoryPeriod period) {
    switch (period) {
      case ExpenseCategoryPeriod.month:
        return 'Bulan Ini';
      case ExpenseCategoryPeriod.year:
        return '1 Tahun Terakhir';
      case ExpenseCategoryPeriod.all:
        return 'Semua Waktu';
    }
  }

  void _showCategoryDetailSheet(
    BuildContext context, {
    required CategoryModel category,
    required int totalAmount,
    required double percentage,
    required String periodLabel,
    required String walletName,
    required List<TransactionModel> transactions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: category.bgColor,
                        borderRadius: BorderRadius.circular(
                          AppBorders.radiusSmall,
                        ),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$walletName · $periodLabel (${percentage.toStringAsFixed(1)}%)',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(totalAmount),
                      style: AppTypography.moneyExpense.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.borderLight, height: 1),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Tidak ada rincian transaksi.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: AppColors.borderLight,
                        height: 1,
                      ),
                      itemBuilder: (_, index) {
                        final tx = transactions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          title: Text(
                            tx.title,
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            AppDateFormatter.formatShortDate(tx.date),
                            style: AppTypography.bodySmall,
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(-tx.amount, withSign: true),
                            style: AppTypography.moneyExpense.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onEditTransaction(tx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final walletId = widget.repository.selectedWalletId;
    final selectedWalletName = walletId == 'all'
        ? 'Semua Dompet'
        : widget.repository.resolveWallet(walletId).name;
    final totalBalance = widget.repository.getBalanceForWallet(walletId);
    final monthlyIncome =
        widget.repository.getMonthlyIncome(now, walletId: walletId);
    final monthlyExpense =
        widget.repository.getMonthlyExpense(now, walletId: walletId);
    final monthlyInsight =
        widget.repository.getMonthlyInsightSummary(now, walletId: walletId);
    final insightCopy = _insightCardCopy(monthlyInsight);

    // Weekly breakdown (Monday to Sunday of current calendar week)
    final weekRange = FinanceRepository.weekRangeFor(now);
    final weeklyBreakdown = widget.repository.getWeeklyCategoryExpenseBreakdown(
      now,
      walletId: walletId,
    );

    // Selected category period breakdown
    late final Map<String, int> categoryPeriodBreakdown;
    DateTime? categoryStart;
    DateTime? categoryEnd;

    switch (_selectedCategoryPeriod) {
      case ExpenseCategoryPeriod.month:
        categoryStart = DateTime(now.year, now.month, 1);
        categoryEnd = DateTime(now.year, now.month + 1, 0);
        categoryPeriodBreakdown =
            widget.repository.getCategoryExpenseBreakdownForPeriod(
          categoryStart,
          categoryEnd,
          walletId: walletId,
        );
      case ExpenseCategoryPeriod.year:
        categoryStart = AppDateFormatter.subtractOneYear(now);
        categoryEnd = now;
        categoryPeriodBreakdown =
            widget.repository.getCategoryExpenseBreakdownForPeriod(
          categoryStart,
          categoryEnd,
          walletId: walletId,
        );
      case ExpenseCategoryPeriod.all:
        categoryPeriodBreakdown =
            widget.repository.getAllTimeCategoryExpenseBreakdown(
          walletId: walletId,
        );
    }

    final recentTransactions = widget.repository.getRecentTransactions(
      limit: 3,
      walletId: walletId,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Personalized Greeting & Profile Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Halo, Syahdan!',
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 22,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const MeemoMascot(
                              size: 26,
                              mood: MeemoMood.happy,
                              showShadow: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelola keuanganmu dengan bijak hari ini',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Avatar Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: AppBorders.borderWidth,
                      ),
                      boxShadow: AppShadows.tactileSmall,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Main Balance Hero Card
              BalanceHeroCard(
                totalBalance: totalBalance,
                monthlyIncome: monthlyIncome,
                monthlyExpense: monthlyExpense,
                selectedWalletName: selectedWalletName,
                onWalletTap: () => _showWalletPicker(context),
                onDetailsTap: () => widget.onNavigateTab(4),
              ),

              const SizedBox(height: 22),

              // Quick Action Bar: Income / Expense
              QuickActionBar(onQuickAdd: widget.onQuickAdd),

              const SizedBox(height: 18),

              // Meemo Smart Insight
              MeemoInsightCard(
                badgeLabel: insightCopy.badgeLabel,
                message: insightCopy.message,
                onActionTap: () => _showInsightDialog(
                  context,
                  monthlyInsight,
                  selectedWalletName,
                ),
              ),

              const SizedBox(height: 18),

              // Weekly Expense Pie Chart (by Category)
              ExpensePieChartCard(
                title: 'Pengeluaran Minggu Ini',
                walletName: selectedWalletName,
                periodLabel: 'Minggu Ini',
                breakdown: weeklyBreakdown,
                emptyTitle: 'Belum ada pengeluaran minggu ini',
                emptyActionHint: 'Catat transaksi pertamamu lewat tombol + di bawah.',
                categoryResolver: widget.repository.resolveCategory,
                onCategoryTap: (category, amount, percentage) {
                  final matchingTxs = widget.repository.getTransactionsForDateRange(
                    start: weekRange.start,
                    end: weekRange.end,
                    typeFilter: TransactionType.expense,
                    categoryFilter: category.id,
                    walletId: walletId,
                  );
                  _showCategoryDetailSheet(
                    context,
                    category: category,
                    totalAmount: amount,
                    percentage: percentage,
                    periodLabel: 'Minggu Ini',
                    walletName: selectedWalletName,
                    transactions: matchingTxs,
                  );
                },
              ),

              const SizedBox(height: 18),

              // Category Expense Pie Chart (Bulan Ini / 1 Tahun / Semua)
              ExpensePieChartCard(
                title: 'Pengeluaran by Kategori',
                walletName: selectedWalletName,
                periodLabel: _periodFullLabel(_selectedCategoryPeriod),
                breakdown: categoryPeriodBreakdown,
                emptyTitle: 'Belum ada pengeluaran pada periode ini',
                emptyActionHint:
                    'Coba pilih periode lain atau catat pengeluaran baru.',
                categoryResolver: widget.repository.resolveCategory,
                headerTrailing: PopupMenuButton<ExpenseCategoryPeriod>(
                  tooltip: 'Pilih periode pengeluaran',
                  initialValue: _selectedCategoryPeriod,
                  onSelected: (period) {
                    setState(() => _selectedCategoryPeriod = period);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: ExpenseCategoryPeriod.month,
                      child: Text('Bulan Ini'),
                    ),
                    PopupMenuItem(
                      value: ExpenseCategoryPeriod.year,
                      child: Text('1 Tahun Terakhir'),
                    ),
                    PopupMenuItem(
                      value: ExpenseCategoryPeriod.all,
                      child: Text('Semua Waktu'),
                    ),
                  ],
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusSmall,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _periodShortLabel(_selectedCategoryPeriod),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.ink,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                onCategoryTap: (category, amount, percentage) {
                  final matchingTxs =
                      (_selectedCategoryPeriod == ExpenseCategoryPeriod.all)
                          ? widget.repository.getTransactionsForPeriod(
                              typeFilter: TransactionType.expense,
                              categoryFilter: category.id,
                              walletId: walletId,
                            )
                          : widget.repository.getTransactionsForDateRange(
                              start: categoryStart!,
                              end: categoryEnd!,
                              typeFilter: TransactionType.expense,
                              categoryFilter: category.id,
                              walletId: walletId,
                            );
                  _showCategoryDetailSheet(
                    context,
                    category: category,
                    totalAmount: amount,
                    percentage: percentage,
                    periodLabel: _periodFullLabel(_selectedCategoryPeriod),
                    walletName: selectedWalletName,
                    transactions: matchingTxs,
                  );
                },
              ),

              const SizedBox(height: 18),

              // Recent Transactions (single box, max 3 items)
              RecentTransactionsSection(
                transactions: recentTransactions,
                categoryResolver: widget.repository.resolveCategory,
                walletResolver: widget.repository.resolveWallet,
                onViewAllTap: () => widget.onNavigateTab(3),
                onEditTransaction: widget.onEditTransaction,
                onDeleteTransaction: (id) => _confirmDelete(context, id),
              ),

              const SizedBox(height: 80), // Padding to avoid bottom nav overlap
            ],
          ),
        ),
      ),
    );
  }
}
