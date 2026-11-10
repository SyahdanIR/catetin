import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/meemo_mascot.dart';
import '../widgets/cashflow_summary_cards.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/income_expense_chart.dart';

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

  late DateTime _selectedMonthDate;
  late int _selectedQuarterYear;
  late int _selectedQuarter;
  late int _selectedYear;
  late DateTime _customStartDate;
  late DateTime _customEndDate;
  String? _customRangeValidationError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthDate = DateTime(now.year, now.month, 1);
    _selectedQuarterYear = now.year;
    _selectedQuarter = AppDateFormatter.quarterForMonth(now.month);
    _selectedYear = now.year;
    _customStartDate = DateTime(now.year, now.month, 1);
    _customEndDate = DateTime(now.year, now.month, now.day);
    widget.repository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectPeriod(ReportPeriod period) {
    setState(() {
      _selectedPeriod = period;
      if (period != ReportPeriod.custom) {
        _customRangeValidationError = null;
      }
    });
  }

  void _prevPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriod.month:
          _selectedMonthDate =
              FinanceRepository.stepMonth(_selectedMonthDate, -1);
          break;
        case ReportPeriod.quarter:
          final prev = FinanceRepository.stepQuarter(
            _selectedQuarterYear,
            _selectedQuarter,
            -1,
          );
          _selectedQuarterYear = prev.year;
          _selectedQuarter = prev.quarter;
          break;
        case ReportPeriod.year:
          _selectedYear -= 1;
          break;
        case ReportPeriod.custom:
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriod.month:
          _selectedMonthDate =
              FinanceRepository.stepMonth(_selectedMonthDate, 1);
          break;
        case ReportPeriod.quarter:
          final next = FinanceRepository.stepQuarter(
            _selectedQuarterYear,
            _selectedQuarter,
            1,
          );
          _selectedQuarterYear = next.year;
          _selectedQuarter = next.quarter;
          break;
        case ReportPeriod.year:
          _selectedYear += 1;
          break;
        case ReportPeriod.custom:
          break;
      }
    });
  }

  Future<void> _pickCustomStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStartDate,
      firstDate: DateTime(2015, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Pilih Tanggal Mulai',
    );
    if (!context.mounted || picked == null) return;

    final error =
        FinanceRepository.validateCustomDateRange(picked, _customEndDate);
    if (error != null) {
      setState(() => _customRangeValidationError = error);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expense,
            content: Text(error),
          ),
        );
      return;
    }

    setState(() {
      _customStartDate = DateTime(picked.year, picked.month, picked.day);
      _customRangeValidationError = null;
    });
  }

  Future<void> _pickCustomEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate,
      firstDate: DateTime(2015, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Pilih Tanggal Akhir',
    );
    if (!context.mounted || picked == null) return;

    final error =
        FinanceRepository.validateCustomDateRange(_customStartDate, picked);
    if (error != null) {
      setState(() => _customRangeValidationError = error);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expense,
            content: Text(error),
          ),
        );
      return;
    }

    setState(() {
      _customEndDate = DateTime(picked.year, picked.month, picked.day);
      _customRangeValidationError = null;
    });
  }

  void _showExportUnavailableDialog() {
    // TODO(future-phase): Implement real PDF/CSV export outside Phase 2 local reporting scope.
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
            const Icon(
              Icons.file_download_outlined,
              color: AppColors.ink,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ekspor Laporan (Segera Hadir)',
                style: AppTypography.headingSmall,
              ),
            ),
          ],
        ),
        content: Text(
          'Fitur ekspor file PDF/CSV belum tersedia pada tahap ini. Seluruh ringkasan arus kas, grafik, dan kategori pada layar ini menampilkan data transaksi lokal Anda secara real-time.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Mengerti',
              style: AppTypography.labelLarge.copyWith(color: AppColors.ink),
            ),
          ),
        ],
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
              Text('Filter Dompet Laporan', style: AppTypography.headingSmall),
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

  @override
  Widget build(BuildContext context) {
    final walletId = widget.repository.selectedWalletId;
    final selectedWalletName = walletId == 'all'
        ? 'Semua Dompet'
        : widget.repository.resolveWallet(walletId).name;

    MonthlyReportData? monthlyData;
    QuarterlyReportData? quarterlyData;
    YearlyReportData? yearlyData;

    late final ReportSummary summary;
    late final List<IncomeExpenseTrendPoint> trendPoints;
    late final PeriodComparison comparison;
    late final String periodTitle;
    late final String chartTitle;
    late final String prevTooltip;
    late final String nextTooltip;

    switch (_selectedPeriod) {
      case ReportPeriod.month:
        monthlyData = widget.repository.getMonthlyReport(
          _selectedMonthDate.year,
          _selectedMonthDate.month,
          walletId: walletId,
        );
        summary = monthlyData.summary;
        trendPoints = monthlyData.trend;
        comparison = monthlyData.comparison;
        periodTitle = AppDateFormatter.formatMonthYear(_selectedMonthDate);
        chartTitle = 'Arus Kas Mingguan ($periodTitle)';
        prevTooltip = 'Bulan Sebelumnya';
        nextTooltip = 'Bulan Berikutnya';
        break;
      case ReportPeriod.quarter:
        quarterlyData = widget.repository.getQuarterlyReport(
          _selectedQuarterYear,
          _selectedQuarter,
          walletId: walletId,
        );
        summary = quarterlyData.summary;
        trendPoints = quarterlyData.monthlyTrend;
        comparison = quarterlyData.comparison;
        periodTitle = AppDateFormatter.formatQuarterYear(
          _selectedQuarterYear,
          _selectedQuarter,
        );
        chartTitle = 'Perbandingan Bulanan Q$_selectedQuarter $_selectedQuarterYear';
        prevTooltip = 'Kuartal Sebelumnya';
        nextTooltip = 'Kuartal Berikutnya';
        break;
      case ReportPeriod.year:
        yearlyData = widget.repository.getYearlyReport(
          _selectedYear,
          walletId: walletId,
        );
        summary = yearlyData.summary;
        trendPoints = yearlyData.monthlyTrend;
        comparison = yearlyData.comparison;
        periodTitle = 'Tahun $_selectedYear';
        chartTitle = 'Tren 12 Bulan ($_selectedYear)';
        prevTooltip = 'Tahun Sebelumnya';
        nextTooltip = 'Tahun Berikutnya';
        break;
      case ReportPeriod.custom:
        summary = widget.repository.getReportSummary(
          startDate: _customStartDate,
          endDate: _customEndDate,
          walletId: walletId,
        );
        trendPoints = widget.repository.getIncomeExpenseTrend(
          startDate: _customStartDate,
          endDate: _customEndDate,
          granularity: ReportPeriod.custom,
          walletId: walletId,
        );
        comparison = widget.repository.getPreviousPeriodComparison(
          startDate: _customStartDate,
          endDate: _customEndDate,
          periodType: ReportPeriod.custom,
          walletId: walletId,
        );
        periodTitle = AppDateFormatter.formatDateRange(
          _customStartDate,
          _customEndDate,
        );
        chartTitle = 'Pemasukan vs Pengeluaran ($periodTitle)';
        prevTooltip = 'Sebelumnya';
        nextTooltip = 'Berikutnya';
        break;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isEntirelyFuture = summary.startDate.isAfter(today);
    final includesFuture = !isEntirelyFuture && summary.endDate.isAfter(today);

    final portfolioOverview = widget.repository.getWalletPortfolios(
      startDate: summary.startDate,
      endDate: summary.endDate,
    );

    final insightText = _buildFactualInsight(
      summary: summary,
      comparison: comparison,
      quarterlyData: quarterlyData,
      yearlyData: yearlyData,
      periodTitle: periodTitle,
      walletName: selectedWalletName,
      isEntirelyFuture: isEntirelyFuture,
    );

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan Finansial',
                          style: AppTypography.displayMedium.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Analisis kesehatan keuangan dan arus kas Anda',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const MeemoMascot(size: 38, mood: MeemoMood.happy),
                ],
              ),

              const SizedBox(height: 10),

              // Active Wallet Filter Pill (synchronized with Dashboard & History)
              InkWell(
                onTap: () => _showWalletPicker(context),
                focusColor: AppColors.ink.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.borderWidth,
                    ),
                    boxShadow: AppShadows.tactileSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Dompet: $selectedWalletName',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 20,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),

              if (widget.repository.isLoading) ...[
                const SizedBox(height: 10),
                Text(
                  'Memuat data laporan...',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 4),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                ),
              ],

              if (widget.repository.errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                    border: Border.all(color: AppColors.expense, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.expenseDark,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.repository.errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.expenseDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.repository.refresh(),
                        child: Text(
                          'Muat Ulang',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.expenseDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

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
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    if (_selectedPeriod == ReportPeriod.custom)
                      _buildCustomDateControls(context)
                    else
                      _buildStepperAndExportRow(
                        periodTitle: periodTitle,
                        prevTooltip: prevTooltip,
                        nextTooltip: nextTooltip,
                      ),

                    if (isEntirelyFuture || includesFuture) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.highlightLight,
                          borderRadius: BorderRadius.circular(
                            AppBorders.radiusSmall,
                          ),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppColors.highlightText,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isEntirelyFuture
                                    ? 'Periode yang dipilih berada di masa mendatang.'
                                    : 'Rentang periode mencakup tanggal mendatang hingga ${AppDateFormatter.formatShortDate(summary.endDate)}.',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.highlightText,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Toggle: Arus Kas vs Kekayaan & Dompet
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
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedTab = ReportTab.cashflow),
                        focusColor: AppColors.ink.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(
                          AppBorders.radiusSmall,
                        ),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
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
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedTab = ReportTab.portfolio),
                        focusColor: AppColors.ink.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(
                          AppBorders.radiusSmall,
                        ),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
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
                              maxLines: 1,
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
                CashflowSummaryCards(
                  income: summary.totalIncome,
                  expense: summary.totalExpense,
                  netBalance: summary.netCashFlow,
                ),

                const SizedBox(height: 16),

                // Income vs Expense Visualization Chart
                IncomeExpenseChart(
                  title: chartTitle,
                  subtitle: '$selectedWalletName · $periodTitle',
                  points: trendPoints,
                ),

                if (quarterlyData != null) ...[
                  const SizedBox(height: 16),
                  _buildQuarterlyComparisonCard(quarterlyData),
                ],

                const SizedBox(height: 16),

                // Meemo Financial Summary (strictly data-backed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
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
                      MeemoMascot(
                        size: 44,
                        mood: summary.hasAnyTransactions &&
                                summary.netCashFlow >= 0
                            ? MeemoMood.saving
                            : MeemoMood.thinking,
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
                              insightText,
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
                _buildStatisticsCard(
                  summary: summary,
                  comparison: comparison,
                  quarterlyData: quarterlyData,
                  yearlyData: yearlyData,
                ),

                const SizedBox(height: 16),

                // Category Spending Breakdown (expenses only)
                CategoryBreakdownChart(
                  breakdown: summary.categoryBreakdown,
                  totalExpense: summary.totalExpense,
                  items: summary.categoryItems,
                  categoryResolver: widget.repository.resolveCategory,
                ),
              ] else ...[
                _buildPortfolioSection(portfolioOverview, periodTitle),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperAndExportRow({
    required String periodTitle,
    required String prevTooltip,
    required String nextTooltip,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevPeriod,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  tooltip: prevTooltip,
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      periodTitle,
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextPeriod,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  tooltip: nextTooltip,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildExportButton(),
      ],
    );
  }

  Widget _buildCustomDateControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePickerBox(
                label: 'Mulai',
                date: _customStartDate,
                onTap: () => _pickCustomStartDate(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDatePickerBox(
                label: 'Akhir',
                date: _customEndDate,
                onTap: () => _pickCustomEndDate(context),
              ),
            ),
          ],
        ),
        if (_customRangeValidationError != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.expenseLight,
              borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
              border: Border.all(color: AppColors.expense, width: 1.0),
            ),
            child: Text(
              _customRangeValidationError!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.expenseDark,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${FinanceRepository.inclusiveDayCount(_customStartDate, _customEndDate)} hari dipilih',
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildExportButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerBox({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      focusColor: AppColors.ink.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
          border: Border.all(color: AppColors.borderLight, width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.inkLight,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    AppDateFormatter.formatShortDate(date),
                    style: AppTypography.labelMedium.copyWith(fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Tooltip(
      message: 'Ekspor PDF/CSV segera hadir',
      child: InkWell(
        onTap: _showExportUnavailableDialog,
        focusColor: AppColors.highlight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
            boxShadow: AppShadows.tactileSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.file_download_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ekspor',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Segera',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.highlight,
                      fontSize: 9,
                      height: 1.0,
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

  Widget _buildPeriodTab(String label, ReportPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: InkWell(
        onTap: () => _selectPeriod(period),
        focusColor: AppColors.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
            border: Border.all(
              color: isSelected ? AppColors.border : AppColors.borderLight,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.inkMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuarterlyComparisonCard(QuarterlyReportData data) {
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
          Text(
            'Rincian Per Bulan di Q${data.quarter} ${data.year}',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < data.monthlyTrend.length; i++) ...[
            if (i > 0)
              const Divider(color: AppColors.borderLight, height: 14),
            () {
              final point = data.monthlyTrend[i];
              final prev = i > 0 ? data.monthlyTrend[i - 1] : null;
              final int? expenseDiff =
                  prev != null ? point.expense - prev.expense : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.fullLabel,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Net ${CurrencyFormatter.format(point.netCashFlow, withSign: true)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: point.netCashFlow >= 0
                              ? AppColors.incomeDark
                              : AppColors.expenseDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Masuk: ${CurrencyFormatter.format(point.income)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.incomeDark,
                        ),
                      ),
                      Text(
                        'Keluar: ${CurrencyFormatter.format(point.expense)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.expenseDark,
                        ),
                      ),
                      if (expenseDiff != null &&
                          (prev!.hasData || point.hasData))
                        Text(
                          expenseDiff == 0
                              ? 'Sama dgn bulan lalu'
                              : expenseDiff > 0
                                  ? 'Keluar +${CurrencyFormatter.formatCompact(expenseDiff)} vs bln sblm'
                                  : 'Keluar ${CurrencyFormatter.formatCompact(expenseDiff)} vs bln sblm',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.inkMuted,
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard({
    required ReportSummary summary,
    required PeriodComparison comparison,
    QuarterlyReportData? quarterlyData,
    YearlyReportData? yearlyData,
  }) {
    final Color? savingColor;
    if (summary.savingRatePercent == null) {
      savingColor = AppColors.inkMuted;
    } else if (summary.savingRatePercent! >= 20) {
      savingColor = AppColors.incomeDark;
    } else if (summary.savingRatePercent! >= 0) {
      savingColor = AppColors.highlightText;
    } else {
      savingColor = AppColors.expenseDark;
    }

    String comparisonText;
    Color comparisonColor = AppColors.inkMuted;
    if (!comparison.hasPreviousExpense && !summary.hasExpenses) {
      comparisonText = 'Belum ada data pembanding';
    } else if (!comparison.hasPreviousExpense) {
      comparisonText = 'Belum ada pengeluaran di periode sebelumnya';
    } else if (comparison.expenseChangePercent != null) {
      final pct = comparison.expenseChangePercent!;
      final sign = pct > 0 ? '+' : '';
      comparisonText =
          '$sign${pct.toStringAsFixed(1)}% (${CurrencyFormatter.format(comparison.expenseDelta, withSign: true)})';
      comparisonColor =
          comparison.expenseDelta > 0 ? AppColors.expenseDark : AppColors.incomeDark;
    } else {
      comparisonText = 'Belum ada data pembanding';
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
          Text('Statistik Finansial', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          _buildStatRow(
            'Transaksi Pemasukan',
            '${summary.incomeCount} transaksi',
            valueColor: AppColors.incomeDark,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildStatRow(
            'Transaksi Pengeluaran',
            '${summary.expenseCount} transaksi',
            valueColor: AppColors.expenseDark,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildStatRow(
            'Rata-rata per Pengeluaran',
            summary.averageExpense != null
                ? CurrencyFormatter.format(summary.averageExpense!)
                : 'Belum ada pengeluaran',
            valueColor: summary.averageExpense != null
                ? AppColors.ink
                : AppColors.inkMuted,
          ),
          if (quarterlyData != null) ...[
            const Divider(color: AppColors.borderLight, height: 16),
            _buildStatRow(
              'Rata-rata Pengeluaran / Bulan',
              quarterlyData.averageMonthlyExpense != null
                  ? CurrencyFormatter.format(quarterlyData.averageMonthlyExpense!)
                  : 'Belum ada pengeluaran',
              valueColor: quarterlyData.averageMonthlyExpense != null
                  ? AppColors.ink
                  : AppColors.inkMuted,
            ),
            const Divider(color: AppColors.borderLight, height: 16),
            _buildStatRow(
              'Bulan Pengeluaran Tertinggi',
              quarterlyData.highestSpendingMonth != null
                  ? '${quarterlyData.highestSpendingMonth!.label} (${CurrencyFormatter.formatCompact(quarterlyData.highestSpendingMonth!.expense)})'
                  : 'Belum ada pengeluaran',
              valueColor: quarterlyData.highestSpendingMonth != null
                  ? AppColors.expenseDark
                  : AppColors.inkMuted,
            ),
          ],
          if (yearlyData != null) ...[
            const Divider(color: AppColors.borderLight, height: 16),
            _buildStatRow(
              'Rata-rata Pengeluaran / Bulan',
              yearlyData.averageMonthlyExpense != null
                  ? CurrencyFormatter.format(yearlyData.averageMonthlyExpense!)
                  : 'Belum ada pengeluaran',
              valueColor: yearlyData.averageMonthlyExpense != null
                  ? AppColors.ink
                  : AppColors.inkMuted,
            ),
            const Divider(color: AppColors.borderLight, height: 16),
            _buildStatRow(
              'Bulan Pengeluaran Tertinggi',
              yearlyData.highestSpendingMonth != null
                  ? '${yearlyData.highestSpendingMonth!.fullLabel} (${CurrencyFormatter.format(yearlyData.highestSpendingMonth!.expense)})'
                  : 'Belum ada pengeluaran',
              valueColor: yearlyData.highestSpendingMonth != null
                  ? AppColors.expenseDark
                  : AppColors.inkMuted,
            ),
            const Divider(color: AppColors.borderLight, height: 16),
            _buildStatRow(
              'Bulan Pengeluaran Terendah',
              yearlyData.lowestSpendingMonth != null
                  ? '${yearlyData.lowestSpendingMonth!.fullLabel} (${CurrencyFormatter.format(yearlyData.lowestSpendingMonth!.expense)})'
                  : (yearlyData.highestSpendingMonth != null
                      ? 'Butuh min. 2 bulan pengeluaran'
                      : 'Belum ada pengeluaran'),
              valueColor: yearlyData.lowestSpendingMonth != null
                  ? AppColors.incomeDark
                  : AppColors.inkMuted,
            ),
          ],
          const Divider(color: AppColors.borderLight, height: 16),
          _buildStatRow(
            'Kategori Pengeluaran Terbesar',
            summary.topExpenseCategory != null
                ? '${summary.topExpenseCategory!.category.name} (${CurrencyFormatter.format(summary.topExpenseCategory!.amount)})'
                : 'Belum ada pengeluaran',
            valueColor: summary.topExpenseCategory != null
                ? AppColors.ink
                : AppColors.inkMuted,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildStatRow(
            'Rasio Masuk vs Keluar',
            summary.incomeToExpenseRatio != null
                ? '${summary.incomeToExpenseRatio!.toStringAsFixed(2)}x'
                : 'Belum tersedia',
            valueColor: summary.incomeToExpenseRatio != null
                ? (summary.incomeToExpenseRatio! >= 1.0
                    ? AppColors.incomeDark
                    : AppColors.expenseDark)
                : AppColors.inkMuted,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildStatRow(
            'Rasio Tabungan (Saving Rate)',
            summary.savingRatePercent != null
                ? '${summary.savingRatePercent!.toStringAsFixed(1)}%'
                : 'Butuh data pemasukan',
            valueColor: savingColor,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildStatRow(
            'Perubahan Keluar vs Periode Lalu',
            comparisonText,
            valueColor: comparisonColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(
    WalletPortfolioOverview overview,
    String periodTitle,
  ) {
    final activeWalletId = widget.repository.selectedWalletId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribusi Saldo Dompet',
                          style: AppTypography.headingSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Saldo aktual & aktivitas ($periodTitle)',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Semua Dompet',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(overview.totalBalance),
                        style: AppTypography.labelLarge.copyWith(
                          color: overview.totalBalance >= 0
                              ? AppColors.ink
                              : AppColors.expenseDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),
              if (overview.wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Belum ada dompet tersimpan.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                )
              else
                for (int i = 0; i < overview.wallets.length; i++) ...[
                  if (i > 0)
                    const Divider(color: AppColors.borderLight, height: 16),
                  _buildWalletPortfolioRow(
                    overview.wallets[i],
                    isActiveFilter:
                        activeWalletId == overview.wallets[i].wallet.id,
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletPortfolioRow(
    WalletPortfolioItem item, {
    required bool isActiveFilter,
  }) {
    final wallet = item.wallet;
    final Color accentColor;
    switch (wallet.id) {
      case 'bank_bca':
        accentColor = AppColors.catTransport;
        break;
      case 'ewallet':
        accentColor = AppColors.catShopping;
        break;
      default:
        accentColor = AppColors.primary;
    }

    return InkWell(
      onTap: () {
        widget.repository.setSelectedWallet(
          isActiveFilter ? 'all' : wallet.id,
        );
      },
      focusColor: AppColors.ink.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Icon(wallet.icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          wallet.name,
                          style: AppTypography.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isActiveFilter)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Filter Aktif',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.periodTransactionCount > 0
                          ? '+${CurrencyFormatter.formatCompact(item.periodIncome)} · -${CurrencyFormatter.formatCompact(item.periodExpense)}'
                          : 'Belum ada transaksi di periode ini',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(item.currentBalance),
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.currentBalance < 0
                          ? AppColors.expenseDark
                          : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: AppTypography.bodyMedium),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.labelLarge.copyWith(
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  String _buildFactualInsight({
    required ReportSummary summary,
    required PeriodComparison comparison,
    QuarterlyReportData? quarterlyData,
    YearlyReportData? yearlyData,
    required String periodTitle,
    required String walletName,
    required bool isEntirelyFuture,
  }) {
    if (!summary.hasAnyTransactions) {
      if (isEntirelyFuture) {
        return 'Belum ada transaksi untuk periode mendatang $periodTitle ($walletName).';
      }
      return 'Belum ada transaksi tercatat pada $periodTitle ($walletName). Catat pemasukan atau pengeluaran untuk melihat analisis keuangan.';
    }

    if (!summary.hasIncome) {
      final topCat = summary.topExpenseCategory?.category.name ?? 'Lainnya';
      return 'Total pengeluaran pada $periodTitle ($walletName) sebesar ${CurrencyFormatter.format(summary.totalExpense)} dari ${summary.expenseCount} transaksi, terbesar di kategori $topCat. Pemasukan belum tercatat pada periode ini.';
    }

    final savingRate = summary.savingRatePercent ?? 0.0;
    final topCatText = summary.topExpenseCategory != null
        ? ' Pengeluaran terbesar ada di ${summary.topExpenseCategory!.category.name} (${CurrencyFormatter.format(summary.topExpenseCategory!.amount)}).'
        : ' Belum ada pengeluaran tercatat.';

    String trendDeltaText = '';
    if (comparison.hasPreviousExpense &&
        comparison.expenseChangePercent != null) {
      final pct = comparison.expenseChangePercent!.abs().toStringAsFixed(1);
      if (comparison.expenseDelta > 0) {
        trendDeltaText = ' Pengeluaran naik $pct% dibanding periode sebelumnya.';
      } else if (comparison.expenseDelta < 0) {
        trendDeltaText = ' Pengeluaran turun $pct% dibanding periode sebelumnya.';
      } else {
        trendDeltaText = ' Pengeluaran sama dengan periode sebelumnya.';
      }
    }

    String periodHighlight = '';
    if (yearlyData?.highestSpendingMonth != null) {
      periodHighlight =
          ' Puncak pengeluaran tahun ini di ${yearlyData!.highestSpendingMonth!.fullLabel}.';
    } else if (quarterlyData?.highestSpendingMonth != null) {
      periodHighlight =
          ' Pengeluaran tertinggi di kuartal ini terjadi pada ${quarterlyData!.highestSpendingMonth!.fullLabel}.';
    }

    if (summary.netCashFlow >= 0) {
      return 'Pemasukan ${CurrencyFormatter.format(summary.totalIncome)} dengan pengeluaran ${CurrencyFormatter.format(summary.totalExpense)} (rasio tabungan ${savingRate.toStringAsFixed(1)}%).$topCatText$periodHighlight$trendDeltaText';
    }

    return 'Pengeluaran melebihi pemasukan sebesar ${CurrencyFormatter.format(-summary.netCashFlow)} pada $periodTitle.$topCatText$periodHighlight$trendDeltaText';
  }
}
