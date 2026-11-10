import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Central state and repository for Catetin financial transactions.
///
/// Implements offline-first SQLite persistence via Drift with reactive updates.
class FinanceRepository extends ChangeNotifier {
  final AppDatabase database;

  FinanceRepository({required this.database}) {
    init();
  }

  final List<TransactionModel> _transactions = [];
  final List<WalletModel> _wallets = [];
  final List<CategoryModel> _categories = [];
  String _selectedWalletId = 'all';
  bool _isInitialized = false;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<WalletModel> get wallets => List.unmodifiable(_wallets);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  String get selectedWalletId => _selectedWalletId;
  bool get isInitialized => _isInitialized;

  void setSelectedWallet(String walletId) {
    _selectedWalletId = walletId;
    notifyListeners();
  }

  /// Initializes the repository by loading persisted data from SQLite.
  Future<void> init() async {
    await _loadFromDatabase();

    // If first launch and database is empty, seed initial starter transactions
    if (_transactions.isEmpty) {
      await _seedInitialTransactions();
      await _loadFromDatabase();
    }

    _isInitialized = true;
    notifyListeners();
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

  Future<void> _seedInitialTransactions() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final initialList = [
      TransactionModel(
        id: 'tx_1',
        title: 'Gaji Bulanan',
        amount: 8500000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: DateTime(year, month, 1, 9, 0),
        note: 'Transfer payroll kantor',
        source: 'manual',
        createdAt: DateTime(year, month, 1, 9, 0),
        updatedAt: DateTime(year, month, 1, 9, 0),
        isRecurring: true,
      ),
      TransactionModel(
        id: 'tx_2',
        title: 'Makan Siang & Kopi',
        amount: 55000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: DateTime(year, month, 2, 12, 30),
        note: 'Ayam geprek & es kopi susu',
        source: 'manual',
        createdAt: DateTime(year, month, 2, 12, 30),
        updatedAt: DateTime(year, month, 2, 12, 30),
      ),
      TransactionModel(
        id: 'tx_3',
        title: 'Tiket Kereta & MRT',
        amount: 32000,
        type: TransactionType.expense,
        categoryId: 'transport',
        walletId: 'main_wallet',
        transactionDate: DateTime(year, month, 3, 8, 15),
        source: 'manual',
        createdAt: DateTime(year, month, 3, 8, 15),
        updatedAt: DateTime(year, month, 3, 8, 15),
      ),
      TransactionModel(
        id: 'tx_4',
        title: 'Belanja Mingguan Supermarket',
        amount: 420000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        walletId: 'main_wallet',
        transactionDate: DateTime(year, month, 4, 16, 45),
        note: 'Sayur, buah, telur',
        source: 'manual',
        createdAt: DateTime(year, month, 4, 16, 45),
        updatedAt: DateTime(year, month, 4, 16, 45),
      ),
      TransactionModel(
        id: 'tx_5',
        title: 'Project Freelance UI Design',
        amount: 2800000,
        type: TransactionType.income,
        categoryId: 'business',
        walletId: 'main_wallet',
        transactionDate: DateTime(year, month, 5, 14, 0),
        note: 'DP termin 1 aplikasi e-commerce',
        source: 'manual',
        createdAt: DateTime(year, month, 5, 14, 0),
        updatedAt: DateTime(year, month, 5, 14, 0),
      ),
      TransactionModel(
        id: 'tx_6',
        title: 'Langganan Internet & Wifi',
        amount: 385000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'main_wallet',
        transactionDate: DateTime(year, month, 6, 10, 0),
        source: 'manual',
        createdAt: DateTime(year, month, 6, 10, 0),
        updatedAt: DateTime(year, month, 6, 10, 0),
        isRecurring: true,
      ),
    ];

    for (final tx in initialList) {
      await database.insertTransactionRow(tx);
    }
  }

  // --- CRUD Operations ---

  Future<void> addTransaction(TransactionModel transaction) async {
    await database.insertTransactionRow(transaction);
    await _loadFromDatabase();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await database.updateTransactionRow(transaction);
    await _loadFromDatabase();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await database.deleteTransactionRow(id);
    await _loadFromDatabase();
    notifyListeners();
  }

  // --- Calculations (AGENTS.md Section 7) ---

  /// Total Balance = Initial Balance + Total Income - Total Expenses
  int getTotalBalance() {
    int total = _wallets.fold(0, (sum, w) => sum + w.initialBalance);
    for (final tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  int getTotalIncome() {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int getTotalExpense() {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Wallet Balance = Wallet Initial Balance + Wallet Income - Wallet Expenses
  int getBalanceForWallet(String walletId) {
    if (walletId == 'all') {
      return getTotalBalance();
    }
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => WalletModel(
        id: walletId,
        name: 'Dompet',
        initialBalance: 0,
        createdAt: DateTime.now(),
      ),
    );

    int total = wallet.initialBalance;
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
            (walletId == null || walletId == 'all' || t.walletId == walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  int getMonthlyExpense(DateTime month, {String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.transactionDate.year == month.year &&
            t.transactionDate.month == month.month &&
            (walletId == null || walletId == 'all' || t.walletId == walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
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
      if (walletId != null && walletId != 'all' && t.walletId != walletId) {
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
        final category = CategoryModel.getById(t.categoryId);
        final matchesCategory = category.name.toLowerCase().contains(query);
        final matchesNotes = t.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, int> getCategoryExpenseBreakdown(DateTime month) {
    final Map<String, int> breakdown = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.transactionDate.year == month.year &&
          tx.transactionDate.month == month.month) {
        breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    return breakdown;
  }

  double getSavingRate(DateTime month) {
    final income = getMonthlyIncome(month);
    final expense = getMonthlyExpense(month);
    if (income <= 0) return 0.0;
    final saved = income - expense;
    if (saved <= 0) return 0.0;
    return (saved / income) * 100;
  }

  // --- Phase 2: Arbitrary Period & Date Range Calculations ---

  /// Income within an arbitrary date range (inclusive of start and end day)
  int getPeriodIncome(DateTime start, DateTime end, {String? walletId}) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            !t.transactionDate.isBefore(s) &&
            !t.transactionDate.isAfter(e) &&
            (walletId == null || walletId == 'all' || t.walletId == walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  /// Expense within an arbitrary date range (inclusive of start and end day)
  int getPeriodExpense(DateTime start, DateTime end, {String? walletId}) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.transactionDate.isBefore(s) &&
            !t.transactionDate.isAfter(e) &&
            (walletId == null || walletId == 'all' || t.walletId == walletId))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  /// Transactions within an arbitrary date range with optional filters
  List<TransactionModel> getTransactionsForDateRange({
    required DateTime start,
    required DateTime end,
    TransactionType? typeFilter,
    String? categoryFilter,
    String? searchQuery,
    String? walletId,
  }) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _transactions.where((t) {
      if (t.transactionDate.isBefore(s) || t.transactionDate.isAfter(e)) {
        return false;
      }
      if (walletId != null && walletId != 'all' && t.walletId != walletId) {
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
        final category = CategoryModel.getById(t.categoryId);
        final matchesCategory = category.name.toLowerCase().contains(query);
        final matchesNotes = t.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Category expense breakdown within an arbitrary date range
  Map<String, int> getCategoryExpenseBreakdownForPeriod(
    DateTime start,
    DateTime end, {
    String? walletId,
  }) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final Map<String, int> breakdown = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          !tx.transactionDate.isBefore(s) &&
          !tx.transactionDate.isAfter(e) &&
          (walletId == null || walletId == 'all' || tx.walletId == walletId)) {
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
          (walletId == null || walletId == 'all' || tx.walletId == walletId)) {
        breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    return breakdown;
  }

  /// Saving rate within an arbitrary date range
  double getPeriodSavingRate(DateTime start, DateTime end, {String? walletId}) {
    final income = getPeriodIncome(start, end, walletId: walletId);
    final expense = getPeriodExpense(start, end, walletId: walletId);
    if (income <= 0) return 0.0;
    final saved = income - expense;
    if (saved <= 0) return 0.0;
    return (saved / income) * 100;
  }
}
