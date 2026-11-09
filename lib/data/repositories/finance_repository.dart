import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

/// Central state and repository for Dompetku financial transactions.
///
/// Implements offline-first state with reactive updates for the UI.
class FinanceRepository extends ChangeNotifier {
  FinanceRepository() {
    _loadInitialSeedData();
  }

  final List<TransactionModel> _transactions = [];
  String _selectedWalletId = 'all';

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  String get selectedWalletId => _selectedWalletId;

  void setSelectedWallet(String walletId) {
    _selectedWalletId = walletId;
    notifyListeners();
  }

  void _loadInitialSeedData() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Seed realistic transactions for immediate testing & visualization
    _transactions.addAll([
      TransactionModel(
        id: 'tx_1',
        title: 'Gaji Bulanan',
        amount: 8500000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        date: DateTime(year, month, 1, 9, 0),
        isRecurring: true,
        notes: 'Transfer payroll kantor',
      ),
      TransactionModel(
        id: 'tx_2',
        title: 'Makan Siang & Kopi',
        amount: 55000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        date: DateTime(year, month, 2, 12, 30),
        notes: 'Ayam geprek & es kopi susu',
      ),
      TransactionModel(
        id: 'tx_3',
        title: 'Tiket Kereta & MRT',
        amount: 32000,
        type: TransactionType.expense,
        categoryId: 'transport',
        walletId: 'ewallet',
        date: DateTime(year, month, 3, 8, 15),
      ),
      TransactionModel(
        id: 'tx_4',
        title: 'Belanja Mingguan Supermarket',
        amount: 420000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        walletId: 'main_wallet',
        date: DateTime(year, month, 4, 16, 45),
        notes: 'Sayur, buah, detergen, telur',
      ),
      TransactionModel(
        id: 'tx_5',
        title: 'Project Freelance UI Design',
        amount: 2800000,
        type: TransactionType.income,
        categoryId: 'freelance',
        walletId: 'bank_bca',
        date: DateTime(year, month, 5, 14, 0),
        notes: 'DP termin 1 aplikasi e-commerce',
      ),
      TransactionModel(
        id: 'tx_6',
        title: 'Langganan Internet & Wifi',
        amount: 385000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'bank_bca',
        date: DateTime(year, month, 6, 10, 0),
        isRecurring: true,
      ),
      TransactionModel(
        id: 'tx_7',
        title: 'Beli Earbuds TWS Baru',
        amount: 275000,
        type: TransactionType.expense,
        categoryId: 'entertainment',
        walletId: 'main_wallet',
        date: DateTime(year, month, 7, 19, 20),
        notes: 'Promo flash sale',
      ),
      TransactionModel(
        id: 'tx_8',
        title: 'Makan Malam Bersama Teman',
        amount: 145000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        date: DateTime(year, month, 8, 20, 10),
      ),
    ]);

    _sortTransactions();
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  void addTransaction(TransactionModel transaction) {
    _transactions.add(transaction);
    _sortTransactions();
    notifyListeners();
  }

  void updateTransaction(TransactionModel transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _sortTransactions();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  double getTotalBalance() {
    double total = 0;
    for (final tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  double getBalanceForWallet(String walletId) {
    if (walletId == 'all') {
      return getTotalBalance();
    }
    double total = 0;
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

  double getMonthlyIncome(DateTime month, {String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == month.year &&
            t.date.month == month.month &&
            (walletId == null || walletId == 'all' || t.walletId == walletId))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyExpense(DateTime month, {String? walletId}) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == month.year &&
            t.date.month == month.month &&
            (walletId == null || walletId == 'all' || t.walletId == walletId))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    return _transactions.take(limit).toList();
  }

  List<TransactionModel> getTransactionsForPeriod({
    DateTime? month,
    TransactionType? typeFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return _transactions.where((t) {
      if (month != null) {
        if (t.date.year != month.year || t.date.month != month.month) {
          return false;
        }
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
        final matchesNotes = t.notes?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, double> getCategoryExpenseBreakdown(DateTime month) {
    final Map<String, double> breakdown = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == month.year &&
          tx.date.month == month.month) {
        breakdown[tx.categoryId] = (breakdown[tx.categoryId] ?? 0.0) + tx.amount;
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
}
