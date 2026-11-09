import 'package:flutter/material.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/finance_repository.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/transactions/screens/transactions_history_screen.dart';
import '../features/transactions/screens/add_transaction_screen.dart';
import '../features/receipt_scanner/screens/receipt_scanner_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import 'widgets/dompetku_bottom_nav.dart';

class NavigationShell extends StatefulWidget {
  final FinanceRepository repository;

  const NavigationShell({
    super.key,
    required this.repository,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;
  TransactionType _quickAddType = TransactionType.expense;
  TransactionModel? _transactionToEdit;

  @override
  void initState() {
    super.initState();
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

  void _handleTabSelect(int index) {
    setState(() {
      _currentIndex = index;
      _transactionToEdit = null;
    });
  }

  void _openAddTransaction(TransactionType type) {
    setState(() {
      _quickAddType = type;
      _transactionToEdit = null;
      _currentIndex = 2; // Jump to Add tab
    });
  }

  void _openEditTransaction(TransactionModel transaction) {
    setState(() {
      _transactionToEdit = transaction;
      _quickAddType = transaction.type;
      _currentIndex = 2; // Jump to Add/Edit tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Home Dashboard
          DashboardScreen(
            repository: widget.repository,
            onNavigateTab: _handleTabSelect,
            onQuickAdd: _openAddTransaction,
            onEditTransaction: _openEditTransaction,
          ),

          // 1: Scan Struk
          ReceiptScannerScreen(
            repository: widget.repository,
            onSaved: () => _handleTabSelect(0),
          ),

          // 2: Add / Edit Transaction
          AddTransactionScreen(
            key: ValueKey(_transactionToEdit?.id ?? 'add_$_quickAddType'),
            repository: widget.repository,
            initialType: _quickAddType,
            transactionToEdit: _transactionToEdit,
            onSaved: () => _handleTabSelect(0),
            onCancel: () => _handleTabSelect(0),
          ),

          // 3: Transaction History
          TransactionsHistoryScreen(
            repository: widget.repository,
            onEditTransaction: _openEditTransaction,
            onAddTransaction: () => _openAddTransaction(TransactionType.expense),
          ),

          // 4: Financial Reports
          ReportsScreen(
            repository: widget.repository,
          ),
        ],
      ),
      bottomNavigationBar: DompetkuBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _handleTabSelect,
      ),
    );
  }
}
