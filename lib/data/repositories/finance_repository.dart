import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

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

  static ({DateTime startInclusive, DateTime endExclusive}) _inclusiveDayBounds(
    DateTime start,
    DateTime end,
  ) {
    return (
      startInclusive: DateTime(start.year, start.month, start.day),
      endExclusive: DateTime(end.year, end.month, end.day + 1),
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
}
