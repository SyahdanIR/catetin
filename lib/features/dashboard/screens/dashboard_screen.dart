import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/widgets/meemo_mascot.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/quick_action_bar.dart';
import '../widgets/meemo_insight_card.dart';
import '../widgets/recent_transactions_section.dart';

class DashboardScreen extends StatelessWidget {
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

  void _showInsightDialog(BuildContext context) {
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
            Text('Insight Dompetku', style: AppTypography.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rasio Tabungan Bulan Ini',
              style: AppTypography.labelLarge.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Berdasarkan catatan transaksi Anda, pengeluaran terbesar ada di kategori Makanan dan Belanja. Anda telah berhasil menghemat 35% dari pemasukan.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.highlightLight,
                borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Text(
                'Saran Meemo: Pertahankan saldo tabungan darurat minimal setara 3 bulan pengeluaran rutin Anda.',
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
        title: Text('Hapus Transaksi?', style: AppTypography.headingSmall),
        content: Text(
          'Transaksi ini akan dihapus dari catatan keuangan Anda.',
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
              repository.deleteTransaction(transactionId);
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
                trailing: repository.selectedWalletId == 'all'
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  repository.setSelectedWallet('all');
                  Navigator.pop(ctx);
                },
              ),
              const Divider(color: AppColors.borderLight, height: 1),
              ...WalletModel.defaultWallets.map((wallet) {
                final isSelected = repository.selectedWalletId == wallet.id;
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
                    repository.setSelectedWallet(wallet.id);
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
    final now = DateTime.now();
    final selectedWalletName = repository.selectedWalletId == 'all'
        ? 'Semua Dompet'
        : WalletModel.getById(repository.selectedWalletId).name;
    final totalBalance = repository.getBalanceForWallet(repository.selectedWalletId);
    final monthlyIncome = repository.getMonthlyIncome(now, walletId: repository.selectedWalletId);
    final monthlyExpense = repository.getMonthlyExpense(now, walletId: repository.selectedWalletId);
    final recentTransactions = repository.getRecentTransactions(limit: 5);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Halo, Syahdan!',
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 22,
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
                onDetailsTap: () => onNavigateTab(4), // Navigate to Reports tab
              ),

              const SizedBox(height: 22),

              // Quick Action Bar: Income / Expense
              QuickActionBar(onQuickAdd: onQuickAdd),

              const SizedBox(height: 18),

              // Meemo Smart Insight
              MeemoInsightCard(
                onActionTap: () => _showInsightDialog(context),
              ),

              const SizedBox(height: 22),

              // Recent Transactions
              RecentTransactionsSection(
                transactions: recentTransactions,
                onViewAllTap: () => onNavigateTab(3), // Navigate to Transactions tab
                onEditTransaction: onEditTransaction,
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
