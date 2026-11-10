import 'package:flutter/foundation.dart';
import '../../core/utils/date_formatter.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/report_models.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

export '../models/report_models.dart';

/// Monthly insight metrics derived strictly from persisted transactions.
class MonthlyInsightSummary {
  final int monthlyIncome;
  final int monthlyExpense;
  final int netBalance;
  final double? savingRatePercent;
  final CategoryModel? topExpenseCategory;
  final int topExpenseAmount;

  const MonthlyInsightSummary({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netBalance,
    required this.savingRatePercent,
    required this.topExpenseCategory,
    required this.topExpenseAmount,
  });

  bool get hasAnyData => monthlyIncome > 0 || monthlyExpense > 0;
}

/// Central state and repository for Catetin financial transactions.
///
/// Implements offline-first SQLite persistence via Drift with reactive updates.
class FinanceRepository extends ChangeNotifier {
  final AppDatabase database;

  FinanceRepository({required this.database});

  final List<TransactionModel> _transactions = [];
  final List<WalletModel> _wallets = [];
  final List<CategoryModel> _categories = [];
  String _selectedWalletId = 'all';
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _initFuture;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<WalletModel> get wallets => List.unmodifiable(_wallets);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  String get selectedWalletId => _selectedWalletId;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedWallet(String walletId) {
    _selectedWalletId = walletId;
    notifyListeners();
  }

  /// Loads persisted data from SQLite once and prevents concurrent initialization runs.
  Future<void> init() {
    if (_isInitialized) return Future.value();
    if (_initFuture != null) return _initFuture!;

    final future = _performInit();
    _initFuture = future;
    return future;
  }

  Future<void> _performInit() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      await _loadFromDatabase();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Gagal memuat data keuangan: $e';
      rethrow;
    } finally {
      _isLoading = false;
      _initFuture = null;
      notifyListeners();
    }
  }

  /// Reloads transactions, wallets, and categories from SQLite.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadFromDatabase();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Gagal memuat ulang data keuangan: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromDatabase() async {
    final txList = await database.getAllTransactions();
    final walletList = await database.getAllWallets();
    final catList = await database.getAllCategories();

    _transactions.clear();
    _transactions.addAll(txList);
    _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    _wallets.clear();
    _wallets.addAll(walletList);

    _categories.clear();
    _categories.addAll(catList);
  }

  // --- CRUD Operations ---

  Future<void> addTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await database.insertTransactionRow(transaction);
      await _loadFromDatabase();
    } catch (e) {
      _errorMessage = 'Gagal menyimpan transaksi: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await database.updateTransactionRow(transaction);
      await _loadFromDatabase();
    } catch (e) {
      _errorMessage = 'Gagal memperbarui transaksi: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await database.deleteTransactionRow(id);
      await _loadFromDatabase();
    } catch (e) {
      _errorMessage = 'Gagal menghapus transaksi: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Database-backed Lookups ---

  CategoryModel? getCategoryById(String id) {
    for (final cat in _categories) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  CategoryModel resolveCategory(String id) {
    return getCategoryById(id) ?? CategoryModel.getById(id);
  }

  WalletModel? getWalletById(String id) {
    for (final wallet in _wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  WalletModel resolveWallet(String id) {
    return getWalletById(id) ?? WalletModel.getById(id);
  }

  // --- Calculations (AGENTS.md Section 7) ---

  static bool _matchesWallet(TransactionModel tx, String? walletId) {
    return walletId == null || walletId == 'all' || tx.walletId == walletId;
  }

  /// Validates and normalizes [start] and [end] to local calendar midnights.
  /// Throws [ArgumentError] if [start] is after [end].
  static ({DateTime start, DateTime end}) normalizeAndValidateDateRange(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    if (normalizedStart.isAfter(normalizedEnd)) {
      throw ArgumentError.value(
        start,
        'startDate',
        'Tanggal mulai tidak boleh setelah tanggal akhir.',
      );
    }
    return (start: normalizedStart, end: normalizedEnd);
  }

  /// Returns an Indonesian validation message when [start] > [end], else null.
  static String? validateCustomDateRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    if (normalizedStart.isAfter(normalizedEnd)) {
      return 'Tanggal mulai tidak boleh setelah tanggal akhir.';
    }
    return null;
  }

  /// Counts inclusive calendar days across [start]..[end] without DST drift.
  static int inclusiveDayCount(DateTime start, DateTime end) {
    final normalized = normalizeAndValidateDateRange(start, end);
    final utcStart = DateTime.utc(
      normalized.start.year,
      normalized.start.month,
      normalized.start.day,
    );
    final utcEnd = DateTime.utc(
      normalized.end.year,
      normalized.end.month,
      normalized.end.day,
    );
    return utcEnd.difference(utcStart).inDays + 1;
  }

  static ({DateTime startInclusive, DateTime endExclusive}) _inclusiveDayBounds(
    DateTime start,
    DateTime end,
  ) {
    final normalized = normalizeAndValidateDateRange(start, end);
    return (
      startInclusive: normalized.start,
      endExclusive: DateTime(
        normalized.end.year,
        normalized.end.month,
        normalized.end.day + 1,
      ),
    );
  }

  /// Net balance difference computed from income and expense totals.
  static int calculateNetAmount(int income, int expense) => income - expense;

  /// Net balance across an arbitrary list of transactions (e.g. a grouped day).
  int calculateTransactionsNetBalance(Iterable<TransactionModel> items) {
    int net = 0;
    for (final tx in items) {
      if (tx.type == TransactionType.income) {
        net += tx.amount;
      } else {
        net -= tx.amount;
      }
    }
    return net;
  }

  /// Total Balance = Initial Balance + Total Income - Total Expenses.
  int getTotalBalance() {
    final initialTotal =
        _wallets.fold<int>(0, (sum, w) => sum + w.initialBalance);
    return initialTotal + calculateTransactionsNetBalance(_transactions);
  }

  int getTotalIncome({String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income && _matchesWallet(t, walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int getTotalExpense({String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense && _matchesWallet(t, walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  /// Wallet Balance = Wallet Initial Balance + Wallet Income - Wallet Expenses.
  int getBalanceForWallet(String walletId) {
    if (walletId == 'all') {
      return getTotalBalance();
    }
    final wallet = getWalletById(walletId);
    int total = wallet?.initialBalance ?? 0;
    for (final tx in _transactions) {
      if (tx.walletId == walletId) {
        if (tx.type == TransactionType.income) {
          total += tx.amount;
        } else {
          total -= tx.amount;
        }
      }
    }
    return total;
  }

  int getMonthlyIncome(DateTime month, {String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.transactionDate.year == month.year &&
            t.transactionDate.month == month.month &&
            _matchesWallet(t, walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int getMonthlyExpense(DateTime month, {String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.transactionDate.year == month.year &&
            t.transactionDate.month == month.month &&
            _matchesWallet(t, walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int getMonthlyNetBalance(DateTime month, {String? walletId}) {
    return calculateNetAmount(
      getMonthlyIncome(month, walletId: walletId),
      getMonthlyExpense(month, walletId: walletId),
    );
  }

  int getNetBalance({DateTime? month, String? walletId}) {
    if (month != null) {
      return getMonthlyNetBalance(month, walletId: walletId);
    }
    return calculateNetAmount(
      getTotalIncome(walletId: walletId),
      getTotalExpense(walletId: walletId),
    );
  }

  int getDailyNetBalance(DateTime date, {String? walletId}) {
    final start = DateTime(date.year, date.month, date.day);
    final nextDay = DateTime(date.year, date.month, date.day + 1);
    return calculateTransactionsNetBalance(
      _transactions.where((t) =>
          !t.transactionDate.isBefore(start) &&
          t.transactionDate.isBefore(nextDay) &&
          _matchesWallet(t, walletId)),
    );
  }

  List<TransactionModel> getRecentTransactions({
    int limit = 5,
    String? walletId,
  }) {
    final filtered = (walletId == null || walletId == 'all')
        ? _transactions
        : _transactions.where((t) => t.walletId == walletId);
    return filtered.take(limit).toList();
  }

  List<TransactionModel> getTransactionsForPeriod({
    DateTime? month,
    TransactionType? typeFilter,
    String? categoryFilter,
    String? searchQuery,
    String? walletId,
  }) {
    return _transactions.where((t) {
      if (month != null) {
        if (t.transactionDate.year != month.year ||
            t.transactionDate.month != month.month) {
          return false;
        }
      }
      if (!_matchesWallet(t, walletId)) {
        return false;
      }
      if (typeFilter != null && t.type != typeFilter) {
        return false;
      }
      if (categoryFilter != null &&
          categoryFilter != 'all' &&
          t.categoryId != categoryFilter) {
        return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final category = resolveCategory(t.categoryId);
        final matchesCategory = category.name.toLowerCase().contains(query);
        final matchesNotes = t.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, int> getCategoryExpenseBreakdown(
    DateTime month, {
    String? walletId,
  }) {
    final Map<String, int> breakdown = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.transactionDate.year == month.year &&
          tx.transactionDate.month == month.month &&
          _matchesWallet(tx, walletId)) {
        breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    return breakdown;
  }

  double getSavingRate(DateTime month, {String? walletId}) {
    final income = getMonthlyIncome(month, walletId: walletId);
    final expense = getMonthlyExpense(month, walletId: walletId);
    if (income <= 0) return 0.0;
    final saved = calculateNetAmount(income, expense);
    if (saved <= 0) return 0.0;
    return (saved / income) * 100;
  }

  MonthlyInsightSummary getMonthlyInsightSummary(
    DateTime month, {
    String? walletId,
  }) {
    final income = getMonthlyIncome(month, walletId: walletId);
    final expense = getMonthlyExpense(month, walletId: walletId);
    final net = calculateNetAmount(income, expense);
    final breakdown = getCategoryExpenseBreakdown(month, walletId: walletId);

    CategoryModel? topCategory;
    int topAmount = 0;
    for (final entry in breakdown.entries) {
      if (entry.value > topAmount) {
        topAmount = entry.value;
        topCategory = resolveCategory(entry.key);
      }
    }

    final double? savingRate =
        income > 0 ? ((income - expense) / income) * 100 : null;

    return MonthlyInsightSummary(
      monthlyIncome: income,
      monthlyExpense: expense,
      netBalance: net,
      savingRatePercent: savingRate,
      topExpenseCategory: topCategory,
      topExpenseAmount: topAmount,
    );
  }

  // --- Arbitrary Period & Date Range Calculations ---

  /// Income within [start] through [end] inclusive of full end calendar day.
  int getPeriodIncome(DateTime start, DateTime end, {String? walletId}) {
    final bounds = _inclusiveDayBounds(start, end);
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            !t.transactionDate.isBefore(bounds.startInclusive) &&
            t.transactionDate.isBefore(bounds.endExclusive) &&
            _matchesWallet(t, walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  /// Expense within [start] through [end] inclusive of full end calendar day.
  int getPeriodExpense(DateTime start, DateTime end, {String? walletId}) {
    final bounds = _inclusiveDayBounds(start, end);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.transactionDate.isBefore(bounds.startInclusive) &&
            t.transactionDate.isBefore(bounds.endExclusive) &&
            _matchesWallet(t, walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int getPeriodNetBalance(DateTime start, DateTime end, {String? walletId}) {
    return calculateNetAmount(
      getPeriodIncome(start, end, walletId: walletId),
      getPeriodExpense(start, end, walletId: walletId),
    );
  }

  /// Transactions within [start] through [end] inclusive of full end calendar day.
  List<TransactionModel> getTransactionsForDateRange({
    required DateTime start,
    required DateTime end,
    TransactionType? typeFilter,
    String? categoryFilter,
    String? searchQuery,
    String? walletId,
  }) {
    final bounds = _inclusiveDayBounds(start, end);
    return _transactions.where((t) {
      if (t.transactionDate.isBefore(bounds.startInclusive) ||
          !t.transactionDate.isBefore(bounds.endExclusive)) {
        return false;
      }
      if (!_matchesWallet(t, walletId)) {
        return false;
      }
      if (typeFilter != null && t.type != typeFilter) {
        return false;
      }
      if (categoryFilter != null &&
          categoryFilter != 'all' &&
          t.categoryId != categoryFilter) {
        return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final category = resolveCategory(t.categoryId);
        final matchesCategory = category.name.toLowerCase().contains(query);
        final matchesNotes = t.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Category expense breakdown within [start] through [end] inclusive.
  Map<String, int> getCategoryExpenseBreakdownForPeriod(
    DateTime start,
    DateTime end, {
    String? walletId,
  }) {
    final bounds = _inclusiveDayBounds(start, end);
    final Map<String, int> breakdown = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          !tx.transactionDate.isBefore(bounds.startInclusive) &&
          tx.transactionDate.isBefore(bounds.endExclusive) &&
          _matchesWallet(tx, walletId)) {
        breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    return breakdown;
  }

  /// Returns the Monday to Sunday date range for [reference]'s calendar week.
  static ({DateTime start, DateTime end}) weekRangeFor(DateTime reference) {
    final monday = DateTime(
      reference.year,
      reference.month,
      reference.day - (reference.weekday - 1),
    );
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    return (start: monday, end: sunday);
  }

  /// Category expense breakdown for [reference]'s calendar week (Monday to Sunday).
  Map<String, int> getWeeklyCategoryExpenseBreakdown(
    DateTime reference, {
    String? walletId,
  }) {
    final range = weekRangeFor(reference);
    return getCategoryExpenseBreakdownForPeriod(
      range.start,
      range.end,
      walletId: walletId,
    );
  }

  /// Category expense breakdown across all recorded transactions.
  Map<String, int> getAllTimeCategoryExpenseBreakdown({String? walletId}) {
    final Map<String, int> breakdown = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          _matchesWallet(tx, walletId)) {
        breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    return breakdown;
  }

  /// Saving rate within an arbitrary date range.
  double getPeriodSavingRate(DateTime start, DateTime end, {String? walletId}) {
    final income = getPeriodIncome(start, end, walletId: walletId);
    final expense = getPeriodExpense(start, end, walletId: walletId);
    if (income <= 0) return 0.0;
    final saved = calculateNetAmount(income, expense);
    if (saved <= 0) return 0.0;
    return (saved / income) * 100;
  }

  // --- Phase 2: Financial Reports & Period Aggregations ---

  static ({DateTime start, DateTime end}) getMonthDateRange(
    int year,
    int month,
  ) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    return (
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 0),
    );
  }

  static ({DateTime start, DateTime end}) getQuarterDateRange(
    int year,
    int quarter,
  ) {
    if (quarter < 1 || quarter > 4) {
      throw RangeError.range(quarter, 1, 4, 'quarter');
    }
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;
    return (
      start: DateTime(year, startMonth, 1),
      end: DateTime(year, endMonth + 1, 0),
    );
  }

  static ({DateTime start, DateTime end}) getYearDateRange(int year) {
    return (
      start: DateTime(year, 1, 1),
      end: DateTime(year, 12, 31),
    );
  }

  static DateTime stepMonth(DateTime current, int delta) {
    final shifted = AppDateFormatter.addMonthsClamped(
      DateTime(current.year, current.month, 1),
      delta,
    );
    return DateTime(shifted.year, shifted.month, 1);
  }

  static ({int year, int quarter}) stepQuarter(
    int year,
    int quarter,
    int delta,
  ) {
    if (quarter < 1 || quarter > 4) {
      throw RangeError.range(quarter, 1, 4, 'quarter');
    }
    final totalQuarters = year * 4 + (quarter - 1) + delta;
    final targetYear =
        totalQuarters >= 0 ? totalQuarters ~/ 4 : ((totalQuarters - 3) ~/ 4);
    final targetQuarter = (totalQuarters % 4) + 1;
    return (year: targetYear, quarter: targetQuarter);
  }

  /// Centralized financial summary for any inclusive calendar date range.
  ReportSummary getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) {
    final normalized = normalizeAndValidateDateRange(startDate, endDate);
    final bounds = _inclusiveDayBounds(normalized.start, normalized.end);
    final effectiveWalletId = walletId ?? 'all';

    int totalIncome = 0;
    int totalExpense = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    final Map<String, int> categoryAmounts = {};
    final Map<String, int> categoryCounts = {};

    for (final tx in _transactions) {
      if (tx.transactionDate.isBefore(bounds.startInclusive) ||
          !tx.transactionDate.isBefore(bounds.endExclusive) ||
          !_matchesWallet(tx, walletId)) {
        continue;
      }
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
        incomeCount++;
      } else {
        totalExpense += tx.amount;
        expenseCount++;
        categoryAmounts[tx.categoryId] =
            (categoryAmounts[tx.categoryId] ?? 0) + tx.amount;
        categoryCounts[tx.categoryId] =
            (categoryCounts[tx.categoryId] ?? 0) + 1;
      }
    }

    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return resolveCategory(a.key).name.compareTo(resolveCategory(b.key).name);
      });

    final sortedBreakdown = <String, int>{
      for (final entry in sortedEntries) entry.key: entry.value,
    };

    final List<CategoryBreakdownItem> categoryItems = totalExpense > 0
        ? sortedEntries.map((entry) {
            final category = resolveCategory(entry.key);
            return CategoryBreakdownItem(
              categoryId: entry.key,
              category: category,
              amount: entry.value,
              percentage: (entry.value / totalExpense) * 100,
              transactionCount: categoryCounts[entry.key] ?? 0,
            );
          }).toList()
        : const [];

    final days = inclusiveDayCount(normalized.start, normalized.end);

    return ReportSummary(
      startDate: normalized.start,
      endDate: normalized.end,
      walletId: effectiveWalletId,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashFlow: calculateNetAmount(totalIncome, totalExpense),
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      dayCount: days,
      averageExpense: expenseCount > 0 ? totalExpense / expenseCount : null,
      averageDailyExpense: expenseCount > 0 ? totalExpense / days : null,
      incomeToExpenseRatio: totalExpense > 0 ? totalIncome / totalExpense : null,
      savingRatePercent: totalIncome > 0
          ? ((totalIncome - totalExpense) / totalIncome) * 100
          : null,
      categoryBreakdown: sortedBreakdown,
      categoryItems: categoryItems,
      topExpenseCategory:
          categoryItems.isNotEmpty ? categoryItems.first : null,
    );
  }

  /// Generates ordered income-vs-expense trend buckets covering [startDate]..[endDate].
  List<IncomeExpenseTrendPoint> getIncomeExpenseTrend({
    required DateTime startDate,
    required DateTime endDate,
    ReportPeriod? granularity,
    String? walletId,
  }) {
    final normalized = normalizeAndValidateDateRange(startDate, endDate);
    final start = normalized.start;
    final end = normalized.end;
    final buckets = _buildTrendBuckets(start, end, granularity);

    final bounds = _inclusiveDayBounds(start, end);
    final incomes = List<int>.filled(buckets.length, 0);
    final expenses = List<int>.filled(buckets.length, 0);
    final counts = List<int>.filled(buckets.length, 0);

    for (final tx in _transactions) {
      if (tx.transactionDate.isBefore(bounds.startInclusive) ||
          !tx.transactionDate.isBefore(bounds.endExclusive) ||
          !_matchesWallet(tx, walletId)) {
        continue;
      }

      for (int i = 0; i < buckets.length; i++) {
        final b = buckets[i];
        final nextDay = DateTime(b.end.year, b.end.month, b.end.day + 1);
        if (!tx.transactionDate.isBefore(b.start) &&
            tx.transactionDate.isBefore(nextDay)) {
          if (tx.type == TransactionType.income) {
            incomes[i] += tx.amount;
          } else {
            expenses[i] += tx.amount;
          }
          counts[i]++;
          break;
        }
      }
    }

    return [
      for (int i = 0; i < buckets.length; i++)
        IncomeExpenseTrendPoint(
          label: buckets[i].label,
          fullLabel: buckets[i].fullLabel,
          startDate: buckets[i].start,
          endDate: buckets[i].end,
          income: incomes[i],
          expense: expenses[i],
          transactionCount: counts[i],
        ),
    ];
  }

  List<({String label, String fullLabel, DateTime start, DateTime end})>
      _buildTrendBuckets(
    DateTime start,
    DateTime end,
    ReportPeriod? granularity,
  ) {
    final isSingleCalendarMonth = start.year == end.year &&
        start.month == end.month &&
        start.day == 1 &&
        end.day == DateTime(start.year, start.month + 1, 0).day;

    if (granularity == ReportPeriod.month && isSingleCalendarMonth) {
      final lastDay = end.day;
      final ranges = <(int, int)>[
        (1, 7),
        (8, 14),
        (15, 21),
        (22, lastDay),
      ];
      return [
        for (int i = 0; i < ranges.length; i++)
          () {
            final bStart = DateTime(start.year, start.month, ranges[i].$1);
            final bEnd = DateTime(start.year, start.month, ranges[i].$2);
            return (
              label: 'M${i + 1}',
              fullLabel: AppDateFormatter.formatDateRange(bStart, bEnd),
              start: bStart,
              end: bEnd,
            );
          }(),
      ];
    }

    if (granularity == ReportPeriod.quarter || granularity == ReportPeriod.year) {
      return _buildMonthlyBuckets(start, end);
    }

    final spanDays = inclusiveDayCount(start, end);
    if (spanDays <= 14) {
      final crossMonth = start.month != end.month || start.year != end.year;
      return [
        for (int i = 0; i < spanDays; i++)
          () {
            final day = DateTime(start.year, start.month, start.day + i);
            final label = crossMonth
                ? '${day.day}/${day.month}'
                : '${day.day} ${AppDateFormatter.monthsShort[day.month - 1]}';
            return (
              label: label,
              fullLabel: AppDateFormatter.formatShortDate(day),
              start: day,
              end: day,
            );
          }(),
      ];
    }

    if (spanDays <= 92) {
      final List<({String label, String fullLabel, DateTime start, DateTime end})>
          weekly = [];
      DateTime cursor = start;
      while (!cursor.isAfter(end)) {
        final rawEnd = DateTime(cursor.year, cursor.month, cursor.day + 6);
        final bEnd = rawEnd.isAfter(end) ? end : rawEnd;
        final sameMonth =
            cursor.month == bEnd.month && cursor.year == bEnd.year;
        final label = sameMonth
            ? '${cursor.day}-${bEnd.day} ${AppDateFormatter.monthsShort[bEnd.month - 1]}'
            : '${cursor.day}/${cursor.month}-${bEnd.day}/${bEnd.month}';
        weekly.add((
          label: label,
          fullLabel: AppDateFormatter.formatDateRange(cursor, bEnd),
          start: cursor,
          end: bEnd,
        ));
        cursor = DateTime(bEnd.year, bEnd.month, bEnd.day + 1);
      }
      return weekly;
    }

    return _buildMonthlyBuckets(start, end);
  }

  List<({String label, String fullLabel, DateTime start, DateTime end})>
      _buildMonthlyBuckets(DateTime start, DateTime end) {
    final List<({String label, String fullLabel, DateTime start, DateTime end})>
        monthly = [];
    final spansMultipleYears = start.year != end.year;
    DateTime monthCursor = DateTime(start.year, start.month, 1);
    final lastMonthStart = DateTime(end.year, end.month, 1);

    while (!monthCursor.isAfter(lastMonthStart)) {
      final monthEnd = DateTime(monthCursor.year, monthCursor.month + 1, 0);
      final clampedStart =
          monthCursor.isBefore(start) ? start : monthCursor;
      final clampedEnd = monthEnd.isAfter(end) ? end : monthEnd;
      final isFullMonth = clampedStart.day == 1 &&
          clampedEnd.day == monthEnd.day;

      final shortMonth = AppDateFormatter.monthsShort[monthCursor.month - 1];
      final label = spansMultipleYears
          ? '$shortMonth ${monthCursor.year % 100}'
          : shortMonth;
      final fullLabel = isFullMonth
          ? AppDateFormatter.formatMonthYear(monthCursor)
          : AppDateFormatter.formatDateRange(clampedStart, clampedEnd);

      monthly.add((
        label: label,
        fullLabel: fullLabel,
        start: clampedStart,
        end: clampedEnd,
      ));

      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }

    return monthly;
  }

  /// Compares [startDate]..[endDate] against its preceding equivalent period.
  PeriodComparison getPreviousPeriodComparison({
    required DateTime startDate,
    required DateTime endDate,
    ReportPeriod? periodType,
    String? walletId,
  }) {
    final normalized = normalizeAndValidateDateRange(startDate, endDate);
    final start = normalized.start;
    final end = normalized.end;

    final ReportPeriod resolvedType = periodType ?? _inferPeriodType(start, end);
    late final ({DateTime start, DateTime end}) prevRange;

    switch (resolvedType) {
      case ReportPeriod.year:
        prevRange = getYearDateRange(start.year - 1);
        break;
      case ReportPeriod.quarter:
        final currentQuarter = AppDateFormatter.quarterForMonth(start.month);
        final prevQ = stepQuarter(start.year, currentQuarter, -1);
        prevRange = getQuarterDateRange(prevQ.year, prevQ.quarter);
        break;
      case ReportPeriod.month:
        final prevMonth = stepMonth(start, -1);
        prevRange = getMonthDateRange(prevMonth.year, prevMonth.month);
        break;
      case ReportPeriod.custom:
        final spanDays = inclusiveDayCount(start, end);
        final prevEnd = DateTime(start.year, start.month, start.day - 1);
        final prevStart = DateTime(
          prevEnd.year,
          prevEnd.month,
          prevEnd.day - (spanDays - 1),
        );
        prevRange = (start: prevStart, end: prevEnd);
        break;
    }

    final currentSummary = getReportSummary(
      startDate: start,
      endDate: end,
      walletId: walletId,
    );
    final previousSummary = getReportSummary(
      startDate: prevRange.start,
      endDate: prevRange.end,
      walletId: walletId,
    );

    final expenseDelta =
        currentSummary.totalExpense - previousSummary.totalExpense;
    final incomeDelta =
        currentSummary.totalIncome - previousSummary.totalIncome;

    return PeriodComparison(
      currentSummary: currentSummary,
      previousSummary: previousSummary,
      previousStartDate: prevRange.start,
      previousEndDate: prevRange.end,
      expenseDelta: expenseDelta,
      expenseChangePercent: previousSummary.totalExpense > 0
          ? (expenseDelta / previousSummary.totalExpense) * 100
          : null,
      incomeDelta: incomeDelta,
      incomeChangePercent: previousSummary.totalIncome > 0
          ? (incomeDelta / previousSummary.totalIncome) * 100
          : null,
      netDelta: currentSummary.netCashFlow - previousSummary.netCashFlow,
    );
  }

  ReportPeriod _inferPeriodType(DateTime start, DateTime end) {
    if (start.month == 1 &&
        start.day == 1 &&
        end.year == start.year &&
        end.month == 12 &&
        end.day == 31) {
      return ReportPeriod.year;
    }
    if (start.year == end.year && start.day == 1) {
      final startQ = AppDateFormatter.quarterForMonth(start.month);
      final qRange = getQuarterDateRange(start.year, startQ);
      if (AppDateFormatter.isSameDay(start, qRange.start) &&
          AppDateFormatter.isSameDay(end, qRange.end)) {
        return ReportPeriod.quarter;
      }
      final mRange = getMonthDateRange(start.year, start.month);
      if (AppDateFormatter.isSameDay(start, mRange.start) &&
          AppDateFormatter.isSameDay(end, mRange.end)) {
        return ReportPeriod.month;
      }
    }
    return ReportPeriod.custom;
  }

  MonthlyReportData getMonthlyReport(
    int year,
    int month, {
    String? walletId,
  }) {
    final range = getMonthDateRange(year, month);
    final summary = getReportSummary(
      startDate: range.start,
      endDate: range.end,
      walletId: walletId,
    );
    final trend = getIncomeExpenseTrend(
      startDate: range.start,
      endDate: range.end,
      granularity: ReportPeriod.month,
      walletId: walletId,
    );
    final comparison = getPreviousPeriodComparison(
      startDate: range.start,
      endDate: range.end,
      periodType: ReportPeriod.month,
      walletId: walletId,
    );
    return MonthlyReportData(
      year: year,
      month: month,
      summary: summary,
      trend: trend,
      comparison: comparison,
    );
  }

  QuarterlyReportData getQuarterlyReport(
    int year,
    int quarter, {
    String? walletId,
  }) {
    final range = getQuarterDateRange(year, quarter);
    final summary = getReportSummary(
      startDate: range.start,
      endDate: range.end,
      walletId: walletId,
    );
    final monthlyTrend = getIncomeExpenseTrend(
      startDate: range.start,
      endDate: range.end,
      granularity: ReportPeriod.quarter,
      walletId: walletId,
    );
    final comparison = getPreviousPeriodComparison(
      startDate: range.start,
      endDate: range.end,
      periodType: ReportPeriod.quarter,
      walletId: walletId,
    );

    final activeExpenseMonths =
        monthlyTrend.where((point) => point.expense > 0).toList();
    final IncomeExpenseTrendPoint? highestSpendingMonth =
        activeExpenseMonths.isEmpty
            ? null
            : activeExpenseMonths.reduce(
                (a, b) => a.expense >= b.expense ? a : b,
              );

    return QuarterlyReportData(
      year: year,
      quarter: quarter,
      summary: summary,
      monthlyTrend: monthlyTrend,
      comparison: comparison,
      averageMonthlyExpense:
          summary.hasExpenses ? summary.totalExpense / 3 : null,
      highestSpendingMonth: highestSpendingMonth,
    );
  }

  YearlyReportData getYearlyReport(
    int year, {
    String? walletId,
  }) {
    final range = getYearDateRange(year);
    final summary = getReportSummary(
      startDate: range.start,
      endDate: range.end,
      walletId: walletId,
    );
    final monthlyTrend = getIncomeExpenseTrend(
      startDate: range.start,
      endDate: range.end,
      granularity: ReportPeriod.year,
      walletId: walletId,
    );
    final comparison = getPreviousPeriodComparison(
      startDate: range.start,
      endDate: range.end,
      periodType: ReportPeriod.year,
      walletId: walletId,
    );

    final activeExpenseMonths =
        monthlyTrend.where((point) => point.expense > 0).toList();
    final IncomeExpenseTrendPoint? highestSpendingMonth =
        activeExpenseMonths.isEmpty
            ? null
            : activeExpenseMonths.reduce(
                (a, b) => a.expense >= b.expense ? a : b,
              );
    // Require at least 2 months with recorded expenses so lowest != trivial single month
    final IncomeExpenseTrendPoint? lowestSpendingMonth =
        activeExpenseMonths.length >= 2
            ? activeExpenseMonths.reduce(
                (a, b) => a.expense <= b.expense ? a : b,
              )
            : null;

    return YearlyReportData(
      year: year,
      summary: summary,
      monthlyTrend: monthlyTrend,
      comparison: comparison,
      averageMonthlyExpense:
          summary.hasExpenses ? summary.totalExpense / 12 : null,
      highestSpendingMonth: highestSpendingMonth,
      lowestSpendingMonth: lowestSpendingMonth,
    );
  }

  /// Real SQLite wallet balances plus cashflow within [startDate]..[endDate].
  WalletPortfolioOverview getWalletPortfolios({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalized = normalizeAndValidateDateRange(startDate, endDate);
    final bounds = _inclusiveDayBounds(normalized.start, normalized.end);

    final Map<String, int> periodIncomeByWallet = {};
    final Map<String, int> periodExpenseByWallet = {};
    final Map<String, int> periodCountByWallet = {};

    for (final tx in _transactions) {
      if (tx.transactionDate.isBefore(bounds.startInclusive) ||
          !tx.transactionDate.isBefore(bounds.endExclusive)) {
        continue;
      }
      periodCountByWallet[tx.walletId] =
          (periodCountByWallet[tx.walletId] ?? 0) + 1;
      if (tx.type == TransactionType.income) {
        periodIncomeByWallet[tx.walletId] =
            (periodIncomeByWallet[tx.walletId] ?? 0) + tx.amount;
      } else {
        periodExpenseByWallet[tx.walletId] =
            (periodExpenseByWallet[tx.walletId] ?? 0) + tx.amount;
      }
    }

    final items = _wallets.map((wallet) {
      return WalletPortfolioItem(
        wallet: wallet,
        currentBalance: getBalanceForWallet(wallet.id),
        periodIncome: periodIncomeByWallet[wallet.id] ?? 0,
        periodExpense: periodExpenseByWallet[wallet.id] ?? 0,
        periodTransactionCount: periodCountByWallet[wallet.id] ?? 0,
      );
    }).toList();

    return WalletPortfolioOverview(
      startDate: normalized.start,
      endDate: normalized.end,
      wallets: items,
      totalBalance: getTotalBalance(),
    );
  }
}
