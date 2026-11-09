import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/meemo_mascot.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_tile.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  final FinanceRepository repository;
  final Function(TransactionModel) onEditTransaction;
  final VoidCallback onAddTransaction;

  const TransactionsHistoryScreen({
    super.key,
    required this.repository,
    required this.onEditTransaction,
    required this.onAddTransaction,
  });

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _selectedType;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = 'all';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _confirmDelete(BuildContext context, String transactionId) {
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
        title: Text('Hapus Catatan?', style: AppTypography.headingSmall),
        content: Text(
          'Catatan transaksi ini akan dihapus permanen dari dompet Anda.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () {
              widget.repository.deleteTransaction(transactionId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Groups filtered transactions by calendar date.
  Map<DateTime, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> list) {
    final Map<DateTime, List<TransactionModel>> groups = {};
    for (final tx in list) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = widget.repository.getTransactionsForPeriod(
      typeFilter: _selectedType,
      categoryFilter: _selectedCategory,
      searchQuery: _searchQuery,
    );

    final groupedMap = _groupTransactions(filteredTransactions);
    final sortedDateKeys = groupedMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
                        'Riwayat Transaksi',
                        style: AppTypography.displayMedium.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${filteredTransactions.length} transaksi tercatat',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: widget.onAddTransaction,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: AppBorders.borderWidth,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Tambah Transaksi',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Filter Component
              TransactionFilterBar(
                selectedType: _selectedType,
                onTypeSelected: (type) => setState(() => _selectedType = type),
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                searchController: _searchController,
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),

              const SizedBox(height: 20),

              // Transaction List grouped by date
              if (filteredTransactions.isEmpty) ...[
                const SizedBox(height: 30),
                EmptyStateView(
                  title: 'Tidak Ada Transaksi Ditemukan',
                  message: 'Coba ubah kata kunci pencarian atau sesuaikan filter Anda.',
                  actionLabel: 'Reset Filter',
                  onAction: _resetFilters,
                  mood: MeemoMood.thinking,
                ),
              ] else ...[
                ...sortedDateKeys.map((date) {
                  final dayTransactions = groupedMap[date]!;
                  // Calculate daily net balance
                  double dailyNet = 0;
                  for (final tx in dayTransactions) {
                    if (tx.type == TransactionType.income) {
                      dailyNet += tx.amount;
                    } else {
                      dailyNet -= tx.amount;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Group Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppDateFormatter.formatGroupDate(date),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(dailyNet, withSign: true),
                              style: AppTypography.labelMedium.copyWith(
                                color: dailyNet >= 0
                                    ? AppColors.incomeDark
                                    : AppColors.expenseDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Transactions in this group
                      ...dayTransactions.map(
                        (tx) => TransactionTile(
                          transaction: tx,
                          onEdit: () => widget.onEditTransaction(tx),
                          onDelete: () => _confirmDelete(context, tx.id),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],

              const SizedBox(height: 80), // Nav bar clearance
            ],
          ),
        ),
      ),
    );
  }
}
