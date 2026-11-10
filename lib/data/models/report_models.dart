import 'category_model.dart';
import 'wallet_model.dart';

enum ReportPeriod {
  month,
  quarter,
  year,
  custom,
}

class CategoryBreakdownItem {
  final String categoryId;
  final CategoryModel category;
  final int amount;
  final double percentage;
  final int transactionCount;

  const CategoryBreakdownItem({
    required this.categoryId,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });
}

class IncomeExpenseTrendPoint {
  final String label;
  final String fullLabel;
  final DateTime startDate;
  final DateTime endDate;
  final int income;
  final int expense;
  final int transactionCount;

  const IncomeExpenseTrendPoint({
    required this.label,
    required this.fullLabel,
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  int get netCashFlow => income - expense;

  bool get hasData => income > 0 || expense > 0 || transactionCount > 0;
}

class ReportSummary {
  final DateTime startDate;
  final DateTime endDate;
  final String walletId;
  final int totalIncome;
  final int totalExpense;
  final int netCashFlow;
  final int incomeCount;
  final int expenseCount;
  final int dayCount;
  final double? averageExpense;
  final double? averageDailyExpense;
  final double? incomeToExpenseRatio;
  final double? savingRatePercent;
  final Map<String, int> categoryBreakdown;
  final List<CategoryBreakdownItem> categoryItems;
  final CategoryBreakdownItem? topExpenseCategory;

  const ReportSummary({
    required this.startDate,
    required this.endDate,
    required this.walletId,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.incomeCount,
    required this.expenseCount,
    required this.dayCount,
    required this.averageExpense,
    required this.averageDailyExpense,
    required this.incomeToExpenseRatio,
    required this.savingRatePercent,
    required this.categoryBreakdown,
    required this.categoryItems,
    required this.topExpenseCategory,
  });

  int get totalTransactionCount => incomeCount + expenseCount;

  bool get hasAnyTransactions => totalTransactionCount > 0;

  bool get hasExpenses => totalExpense > 0 && expenseCount > 0;

  bool get hasIncome => totalIncome > 0 && incomeCount > 0;
}

class PeriodComparison {
  final ReportSummary currentSummary;
  final ReportSummary previousSummary;
  final DateTime previousStartDate;
  final DateTime previousEndDate;
  final int expenseDelta;
  final double? expenseChangePercent;
  final int incomeDelta;
  final double? incomeChangePercent;
  final int netDelta;

  const PeriodComparison({
    required this.currentSummary,
    required this.previousSummary,
    required this.previousStartDate,
    required this.previousEndDate,
    required this.expenseDelta,
    required this.expenseChangePercent,
    required this.incomeDelta,
    required this.incomeChangePercent,
    required this.netDelta,
  });

  bool get hasPreviousData => previousSummary.hasAnyTransactions;

  bool get hasPreviousExpense => previousSummary.totalExpense > 0;

  bool get hasPreviousIncome => previousSummary.totalIncome > 0;
}

class MonthlyReportData {
  final int year;
  final int month;
  final ReportSummary summary;
  final List<IncomeExpenseTrendPoint> trend;
  final PeriodComparison comparison;

  const MonthlyReportData({
    required this.year,
    required this.month,
    required this.summary,
    required this.trend,
    required this.comparison,
  });
}

class QuarterlyReportData {
  final int year;
  final int quarter;
  final ReportSummary summary;
  final List<IncomeExpenseTrendPoint> monthlyTrend;
  final PeriodComparison comparison;
  final double? averageMonthlyExpense;
  final IncomeExpenseTrendPoint? highestSpendingMonth;

  const QuarterlyReportData({
    required this.year,
    required this.quarter,
    required this.summary,
    required this.monthlyTrend,
    required this.comparison,
    required this.averageMonthlyExpense,
    required this.highestSpendingMonth,
  });
}

class YearlyReportData {
  final int year;
  final ReportSummary summary;
  final List<IncomeExpenseTrendPoint> monthlyTrend;
  final PeriodComparison comparison;
  final double? averageMonthlyExpense;
  final IncomeExpenseTrendPoint? highestSpendingMonth;
  final IncomeExpenseTrendPoint? lowestSpendingMonth;

  const YearlyReportData({
    required this.year,
    required this.summary,
    required this.monthlyTrend,
    required this.comparison,
    required this.averageMonthlyExpense,
    required this.highestSpendingMonth,
    required this.lowestSpendingMonth,
  });
}

class WalletPortfolioItem {
  final WalletModel wallet;
  final int currentBalance;
  final int periodIncome;
  final int periodExpense;
  final int periodTransactionCount;

  const WalletPortfolioItem({
    required this.wallet,
    required this.currentBalance,
    required this.periodIncome,
    required this.periodExpense,
    required this.periodTransactionCount,
  });

  int get periodNetCashFlow => periodIncome - periodExpense;
}

class WalletPortfolioOverview {
  final DateTime startDate;
  final DateTime endDate;
  final List<WalletPortfolioItem> wallets;
  final int totalBalance;

  const WalletPortfolioOverview({
    required this.startDate,
    required this.endDate,
    required this.wallets,
    required this.totalBalance,
  });
}
