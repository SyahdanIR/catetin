import 'package:catetin/core/theme/app_colors.dart';
import 'package:catetin/core/theme/app_shadows.dart';
import 'package:catetin/core/theme/app_theme.dart';
import 'package:catetin/core/utils/date_formatter.dart';
import 'package:catetin/data/database/app_database.dart';
import 'package:catetin/data/models/transaction_model.dart';
import 'package:catetin/data/repositories/finance_repository.dart';
import 'package:catetin/features/dashboard/screens/dashboard_screen.dart';
import 'package:catetin/features/dashboard/widgets/balance_hero_card.dart';
import 'package:catetin/features/dashboard/widgets/expense_pie_chart_card.dart';
import 'package:catetin/features/dashboard/widgets/recent_transactions_section.dart';
import 'package:catetin/features/receipt_scanner/screens/receipt_scanner_screen.dart';
import 'package:catetin/features/reports/screens/reports_screen.dart';
import 'package:catetin/features/reports/widgets/cashflow_summary_cards.dart';
import 'package:catetin/features/reports/widgets/category_breakdown_chart.dart';
import 'package:catetin/features/reports/widgets/income_expense_chart.dart';
import 'package:catetin/features/transactions/screens/add_transaction_screen.dart';
import 'package:catetin/features/transactions/screens/transactions_history_screen.dart';
import 'package:catetin/features/transactions/widgets/transaction_filter_bar.dart';
import 'package:catetin/features/transactions/widgets/transaction_tile.dart';
import 'package:catetin/main.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingWriteAppDatabase extends AppDatabase {
  bool failWrites = true;

  _FailingWriteAppDatabase(super.e);

  @override
  Future<void> insertTransactionRow(TransactionModel tx) async {
    if (failWrites) {
      throw StateError('Simulated SQLite insert failure');
    }
    return super.insertTransactionRow(tx);
  }

  @override
  Future<void> deleteTransactionRow(String id) async {
    if (failWrites) {
      throw StateError('Simulated SQLite delete failure');
    }
    return super.deleteTransactionRow(id);
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('Catetin smoke test - dashboard renders greeting and tabs on empty DB',
      (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();

    await tester.pumpWidget(CatetinApp(repository: repository));

    expect(find.text('Halo, Syahdan!'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Scan Struk'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('Belum Ada Transaksi'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Laporan Finansial'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await database.close();
  });

  testWidgets(
      'ReceiptScannerScreen renders cleanly on 360px and shows error without false success on failed DB write',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = _FailingWriteAppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ReceiptScannerScreen(
          repository: repository,
          onSaved: () => saved = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Hasil Ekstraksi Struk'), findsOneWidget);
    expect(find.text('Pindai Ulang'), findsOneWidget);
    expect(find.text('Simpan ke Dompet'), findsOneWidget);

    await tester.ensureVisible(find.text('Simpan ke Dompet'));
    await tester.tap(find.text('Simpan ke Dompet'));
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(find.text('Gagal menyimpan transaksi struk. Coba lagi.'), findsOneWidget);
    expect(find.text('Transaksi struk berhasil disimpan ke dompet!'), findsNothing);
    expect(find.text('Indomaret Point'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await database.close();
  });

  testWidgets(
      'TransactionFilterBar search field renders clean OutlineInputBorder on 360px screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    TransactionType? selectedType;
    String selectedCategory = 'all';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) {
                return TransactionFilterBar(
                  selectedType: selectedType,
                  onTypeSelected: (type) => setState(() => selectedType = type),
                  selectedCategory: selectedCategory,
                  onCategorySelected: (cat) =>
                      setState(() => selectedCategory = cat),
                  searchController: searchController,
                  onSearchChanged: (_) => setState(() {}),
                  onClearSearch: () {
                    searchController.clear();
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    final searchFieldFinder = find.byType(TextField);
    expect(searchFieldFinder, findsOneWidget);

    final textField = tester.widget<TextField>(searchFieldFinder);
    final decoration = textField.decoration!;
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, AppColors.background);
    expect(decoration.enabledBorder, isA<OutlineInputBorder>());
    final enabledBorder = decoration.enabledBorder as OutlineInputBorder;
    expect(
      enabledBorder.borderRadius,
      BorderRadius.circular(AppBorders.radiusMedium),
    );
    expect(decoration.focusedBorder, isA<OutlineInputBorder>());

    await tester.enterText(searchFieldFinder, 'Internet');
    await tester.pump();
    expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pump();
    expect(searchController.text, isEmpty);
    expect(find.byIcon(Icons.clear_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TransactionTile displays negative sign for expenses and positive sign for income',
      (WidgetTester tester) async {
    final now = DateTime(2026, 11, 6);
    final expenseTx = TransactionModel(
      id: 'tx_exp_1',
      title: 'Langganan Internet & Wifi',
      amount: 385000,
      type: TransactionType.expense,
      categoryId: 'bills',
      walletId: 'main_wallet',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
      isRecurring: true,
    );
    final incomeTx = TransactionModel(
      id: 'tx_inc_1',
      title: 'Project Freelance UI Design',
      amount: 2800000,
      type: TransactionType.income,
      categoryId: 'business',
      walletId: 'main_wallet',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: [
              TransactionTile(transaction: expenseTx),
              TransactionTile(transaction: incomeTx),
            ],
          ),
        ),
      ),
    );

    expect(find.text('- Rp 385.000'), findsOneWidget);
    expect(find.text('+ Rp 385.000'), findsNothing);
    expect(find.text('+ Rp 2.800.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'DashboardScreen displays neutral empty insight state instead of hardcoded 35% when no transactions exist',
      (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: DashboardScreen(
          repository: repository,
          onNavigateTab: (_) {},
          onQuickAdd: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    expect(find.textContaining('35%'), findsNothing);
    expect(
      find.text(
        'Belum ada transaksi bulan ini. Catat pemasukan dan pengeluaranmu untuk melihat ringkasan.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byTooltip('Lihat Tips Selengkapnya'));
    await tester.tap(find.byTooltip('Lihat Tips Selengkapnya'));
    await tester.pumpAndSettle();

    expect(find.text('Data Bulan Ini Belum Cukup'), findsOneWidget);
    expect(find.textContaining('35%'), findsNothing);

    await database.close();
  });

  testWidgets(
      'DashboardScreen renders pie chart cards, real insight, DB wallet picker with negative balance formatting, and 3 recent transactions on 360px screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12, 0);
    // 4 explicit persisted transactions so RecentTransactionsSection limits to 3
    // and annual pie chart includes older 'shopping' expense.
    await repository.addTransaction(TransactionModel(
      id: 'dash_old_shop',
      title: 'Belanja Bulanan Lama',
      amount: 420000,
      type: TransactionType.expense,
      categoryId: 'shopping',
      walletId: 'main_wallet',
      transactionDate: today.subtract(const Duration(days: 15)),
      createdAt: today,
      updatedAt: today,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'dash_inc_1',
      title: 'Gaji Bulan Ini',
      amount: 10000000,
      type: TransactionType.income,
      categoryId: 'salary',
      walletId: 'main_wallet',
      transactionDate: DateTime(now.year, now.month, 1, 9, 0),
      createdAt: today,
      updatedAt: today,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'dash_exp_bca',
      title: 'Bensin Bank BCA',
      amount: 100000,
      type: TransactionType.expense,
      categoryId: 'transport',
      walletId: 'bank_bca',
      transactionDate: today.subtract(const Duration(hours: 2)),
      createdAt: today,
      updatedAt: today,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'dash_exp_food',
      title: 'Makan Siang Minggu Ini',
      amount: 50000,
      type: TransactionType.expense,
      categoryId: 'food',
      walletId: 'main_wallet',
      transactionDate: today,
      createdAt: today,
      updatedAt: today,
    ));

    int? navigatedTab;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AnimatedBuilder(
          animation: repository,
          builder: (context, _) => DashboardScreen(
            repository: repository,
            onNavigateTab: (tab) => navigatedTab = tab,
            onQuickAdd: (_) {},
            onEditTransaction: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(ExpensePieChartCard), findsNWidgets(2));
    expect(find.text('Pengeluaran Minggu Ini'), findsOneWidget);
    expect(find.text('Pengeluaran by Kategori'), findsOneWidget);
    expect(find.textContaining('35%'), findsNothing);

    // RecentTransactionsSection must show only 3 newest items
    expect(find.byType(RecentTransactionsSection), findsOneWidget);
    final recentTxs = repository.getRecentTransactions(limit: 3);
    expect(recentTxs.length, 3);
    for (final tx in recentTxs) {
      expect(
        find.descendant(
          of: find.byType(RecentTransactionsSection),
          matching: find.text(tx.title),
        ),
        findsOneWidget,
      );
    }
    final oldestTx = repository.transactions.last;
    expect(
      find.descendant(
        of: find.byType(RecentTransactionsSection),
        matching: find.text(oldestTx.title),
      ),
      findsNothing,
    );

    // Verify real insight dialog content (computed, never hardcoded 35%)
    await tester.ensureVisible(find.byTooltip('Lihat Tips Selengkapnya'));
    await tester.tap(find.byTooltip('Lihat Tips Selengkapnya'));
    await tester.pumpAndSettle();
    expect(find.text('Rasio Tabungan Bulan Ini'), findsOneWidget);
    expect(find.textContaining('35%'), findsNothing);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    // Open wallet picker from BalanceHeroCard and select bank_bca (-Rp 100.000)
    final heroSemuaDompet = find.descendant(
      of: find.byType(BalanceHeroCard),
      matching: find.text('Semua Dompet'),
    );
    await tester.ensureVisible(heroSemuaDompet);
    await tester.pumpAndSettle();
    await tester.tap(heroSemuaDompet);
    await tester.pumpAndSettle();
    expect(find.text('Dompet Utama'), findsOneWidget);
    expect(find.text('Rekening Bank'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
    await tester.tap(find.text('Rekening Bank'));
    await tester.pumpAndSettle();
    expect(find.text('-Rp 100.000'), findsOneWidget);

    // Reset back to All Wallets for category sheet check
    final heroRekeningBank = find.descendant(
      of: find.byType(BalanceHeroCard),
      matching: find.text('Rekening Bank'),
    );
    await tester.ensureVisible(heroRekeningBank);
    await tester.pumpAndSettle();
    await tester.tap(heroRekeningBank);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua Dompet (Total)'));
    await tester.pumpAndSettle();

    // Tap Lihat Semua -> navigates to Transactions tab (3)
    await tester.ensureVisible(find.text('Lihat Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Semua'));
    await tester.pumpAndSettle();
    expect(navigatedTab, 3);

    // Period dropdown in Pengeluaran by Kategori switches period cleanly
    final periodMenuButton = find.byTooltip('Pilih periode pengeluaran');
    await tester.ensureVisible(periodMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(periodMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Tahun Terakhir'));
    await tester.pumpAndSettle();
    expect(find.text('1 Tahun'), findsOneWidget);

    // Tapping category legend opens detail bottom sheet
    await tester.tap(
      find.descendant(
        of: find.byType(ExpensePieChartCard).last,
        matching: find.text('Belanja'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belanja Bulanan Lama'), findsOneWidget);
    Navigator.of(tester.element(find.text('Belanja Bulanan Lama'))).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await database.close();
  });

  testWidgets('ExpensePieChartCard shows empty state cleanly on 360px screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: ExpensePieChartCard(
              title: 'Pengeluaran Minggu Ini',
              walletName: 'Dompet Utama',
              periodLabel: 'Minggu Ini',
              breakdown: {},
              emptyTitle: 'Belum ada pengeluaran minggu ini',
              emptyActionHint:
                  'Catat transaksi pertamamu lewat tombol + di bawah.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Belum ada pengeluaran minggu ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AddTransactionScreen saves to SQLite using DB wallets and categories',
      (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AddTransactionScreen(
          repository: repository,
          onSaved: () => saved = true,
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '50000');
    await tester.enterText(fields.at(1), 'Beli Roti');

    // Select DB-backed wallet option "Rekening Bank"
    await tester.ensureVisible(find.text('Rekening Bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rekening Bank'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Catat Transaksi Ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat Transaksi Ini'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(find.text('Transaksi berhasil disimpan!'), findsOneWidget);
    expect(repository.transactions.length, 1);
    expect(repository.transactions.first.title, 'Beli Roti');
    expect(repository.transactions.first.amount, 50000);
    expect(repository.transactions.first.walletId, 'bank_bca');
    expect(repository.getBalanceForWallet('bank_bca'), -50000);

    await database.close();
  });

  testWidgets(
      'AddTransactionScreen preserves form data and avoids false success when SQLite write fails',
      (WidgetTester tester) async {
    final database = _FailingWriteAppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AddTransactionScreen(
          repository: repository,
          onSaved: () => saved = true,
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '75000');
    await tester.enterText(fields.at(1), 'Tiket Kereta');
    await tester.enterText(fields.at(2), 'Catatan penting');

    await tester.ensureVisible(find.text('Catat Transaksi Ini'));
    await tester.tap(find.text('Catat Transaksi Ini'));
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(find.text('Transaksi berhasil disimpan!'), findsNothing);
    expect(find.text('Gagal menyimpan transaksi. Coba lagi.'), findsOneWidget);
    expect(repository.transactions, isEmpty);

    // Input values must still be preserved for retry
    expect(find.text('75000'), findsOneWidget);
    expect(find.text('Tiket Kereta'), findsOneWidget);
    expect(find.text('Catatan penting'), findsOneWidget);

    await database.close();
  });

  testWidgets(
      'TransactionsHistoryScreen renders on 360px without overflow, filters by wallet & search, and handles delete failures cleanly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = _FailingWriteAppDatabase(NativeDatabase.memory())
      ..failWrites = false;
    final repository = FinanceRepository(database: database);
    await repository.init();

    final now = DateTime(2026, 11, 10, 12, 0);
    await repository.addTransaction(TransactionModel(
      id: 'h_main_1',
      title: 'Makan Siang Panjang Sekali Untuk Uji Responsif Layar Sempit',
      amount: 55000,
      type: TransactionType.expense,
      categoryId: 'food',
      walletId: 'main_wallet',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'h_bca_1',
      title: 'Transfer Gaji BCA',
      amount: 5000000,
      type: TransactionType.income,
      categoryId: 'salary',
      walletId: 'bank_bca',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    ));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AnimatedBuilder(
          animation: repository,
          builder: (context, _) => TransactionsHistoryScreen(
            repository: repository,
            onEditTransaction: (_) {},
            onAddTransaction: () {},
          ),
        ),
      ),
    );

    expect(find.text('2 transaksi tercatat'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Wallet filtering must update TransactionsHistoryScreen
    repository.setSelectedWallet('bank_bca');
    await tester.pumpAndSettle();
    expect(find.text('1 transaksi · Rekening Bank'), findsOneWidget);
    expect(find.text('Transfer Gaji BCA'), findsOneWidget);
    expect(
      find.text('Makan Siang Panjang Sekali Untuk Uji Responsif Layar Sempit'),
      findsNothing,
    );

    // Reset wallet filter to all and test search + failed delete handling
    repository.setSelectedWallet('all');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Transfer');
    await tester.pumpAndSettle();
    expect(find.text('Transfer Gaji BCA'), findsOneWidget);
    expect(
      find.text('Makan Siang Panjang Sekali Untuk Uji Responsif Layar Sempit'),
      findsNothing,
    );

    database.failWrites = true;
    await tester.ensureVisible(find.text('Hapus'));
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hapus'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transaksi berhasil dihapus'), findsNothing);
    expect(find.text('Gagal menghapus transaksi.'), findsOneWidget);
    expect(repository.transactions.length, 2);

    // Clear search and perform successful delete
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    database.failWrites = false;

    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hapus'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transaksi berhasil dihapus'), findsOneWidget);
    expect(repository.transactions.length, 1);
    expect(tester.takeException(), isNull);

    await database.close();
  });

  testWidgets(
      'ReportsScreen Monthly, Quarterly, Yearly views render real SQLite data, update across wallets, and replace fake portfolio/export placeholders on 360px screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 2, 10, 0);
    final prevMonthDate = FinanceRepository.stepMonth(now, -1);
    final earlierThisYearMonth =
        now.month > 1 ? DateTime(now.year, 1, 12, 10, 0) : DateTime(now.year, 2, 3, 9, 0);

    await repository.addTransaction(TransactionModel(
      id: 'rep_cur_inc',
      title: 'Gaji Bulan Berjalan',
      amount: 8000000,
      type: TransactionType.income,
      categoryId: 'salary',
      walletId: 'main_wallet',
      transactionDate: currentMonthStart,
      createdAt: currentMonthStart,
      updatedAt: currentMonthStart,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'rep_cur_exp_food',
      title: 'Belanja Dapur',
      amount: 1500000,
      type: TransactionType.expense,
      categoryId: 'food',
      walletId: 'main_wallet',
      transactionDate: currentMonthStart,
      createdAt: currentMonthStart,
      updatedAt: currentMonthStart,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'rep_cur_exp_bca',
      title: 'Cicilan BCA',
      amount: 500000,
      type: TransactionType.expense,
      categoryId: 'bills',
      walletId: 'bank_bca',
      transactionDate: currentMonthStart,
      createdAt: currentMonthStart,
      updatedAt: currentMonthStart,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'rep_prev_exp',
      title: 'Transport Bulan Lalu',
      amount: 400000,
      type: TransactionType.expense,
      categoryId: 'transport',
      walletId: 'ewallet',
      transactionDate: DateTime(prevMonthDate.year, prevMonthDate.month, 10, 11, 0),
      createdAt: now,
      updatedAt: now,
    ));
    await repository.addTransaction(TransactionModel(
      id: 'rep_jan_exp',
      title: 'Belanja Awal Tahun',
      amount: 250000,
      type: TransactionType.expense,
      categoryId: 'shopping',
      walletId: 'bank_bca',
      transactionDate: earlierThisYearMonth,
      createdAt: now,
      updatedAt: now,
    ));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ReportsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    // Default Monthly view matches current month
    expect(find.text(AppDateFormatter.formatMonthYear(now)), findsOneWidget);
    expect(find.byType(CashflowSummaryCards), findsOneWidget);
    expect(find.byType(IncomeExpenseChart), findsOneWidget);
    expect(find.byType(CategoryBreakdownChart), findsOneWidget);
    expect(find.text('1 transaksi'), findsNWidgets(1)); // 1 income tx
    expect(find.text('2 transaksi'), findsNWidgets(1)); // 2 expense tx
    expect(find.text('Makanan & Minuman'), findsWidgets);
    expect(find.text('Tagihan'), findsWidgets);
    expect(find.textContaining('NaN'), findsNothing);
    expect(find.textContaining('Infinity'), findsNothing);
    expect(find.textContaining('13.082.900'), findsNothing);
    expect(find.textContaining('25.400.000'), findsNothing);
    expect(tester.takeException(), isNull);

    // Export button opens honest Coming Soon dialog (closable via button & Escape)
    await tester.tap(find.text('Ekspor'));
    await tester.pumpAndSettle();
    expect(find.text('Ekspor Laporan (Segera Hadir)'), findsOneWidget);
    expect(find.textContaining('berhasil diekspor'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Ekspor Laporan (Segera Hadir)'), findsNothing);

    // Keyboard Tab focuses interactive controls and opens Export dialog via Enter
    await tester.tap(find.text('Ekspor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Step backward to previous month and forward back to current month
    await tester.tap(find.byTooltip('Bulan Sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text(AppDateFormatter.formatMonthYear(prevMonthDate)), findsOneWidget);
    expect(find.text('Transportasi'), findsWidgets);
    await tester.tap(find.byTooltip('Bulan Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text(AppDateFormatter.formatMonthYear(now)), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Quarterly tab and verify 3-month comparison renders cleanly
    await tester.tap(find.text('Kuartal'));
    await tester.pumpAndSettle();
    final curQuarter = AppDateFormatter.quarterForMonth(now.month);
    expect(find.text('Rincian Per Bulan di Q$curQuarter ${now.year}'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Yearly tab and verify 12 months chart labels, bar interaction & stats
    await tester.tap(find.text('Tahun'));
    await tester.pumpAndSettle();
    expect(find.text('Tahun ${now.year}'), findsOneWidget);
    expect(find.text('Bulan Pengeluaran Tertinggi'), findsOneWidget);
    expect(find.text('Bulan Pengeluaran Terendah'), findsOneWidget);
    expect(find.text('Des'), findsOneWidget);
    await tester.ensureVisible(find.byType(IncomeExpenseChart));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Des'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Des'));
    await tester.pumpAndSettle();
    expect(find.text('Desember ${now.year}'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Filter wallet to Rekening Bank via ReportsScreen wallet pill
    await tester.ensureVisible(find.text('Dompet: Semua Dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dompet: Semua Dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rekening Bank'));
    await tester.pumpAndSettle();
    expect(find.text('Dompet: Rekening Bank'), findsOneWidget);
    expect(find.text('0 transaksi'), findsOneWidget); // 0 income in bank_bca
    expect(tester.takeException(), isNull);

    // Check Kekayaan & Dompet displays real wallet balances
    await tester.ensureVisible(find.text('Kekayaan & Dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kekayaan & Dompet'));
    await tester.pumpAndSettle();
    expect(find.text('Distribusi Saldo Dompet'), findsOneWidget);
    expect(find.text('Rp 6.500.000'), findsOneWidget); // main_wallet: 8jt - 1.5jt
    expect(find.text('-Rp 750.000'), findsOneWidget); // bank_bca: -500rb - 250rb
    expect(find.text('-Rp 400.000'), findsOneWidget); // ewallet: -400rb
    expect(find.text('Rp 5.350.000'), findsOneWidget); // total across 3 SQLite wallets

    expect(tester.takeException(), isNull);
    await database.close();
  });

  testWidgets(
      'ReportsScreen Custom date range validates start <= end, handles future dates, and displays zero-expense empty breakdown safely',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ReportsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    // Empty month shows clean neutral states with zero NaN/Infinity
    expect(find.text('Belum ada arus kas pada periode ini'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran pada periode ini'), findsOneWidget);
    expect(find.textContaining('NaN'), findsNothing);

    // Switch to Custom tab and attempt selecting End Date before Start Date (1st of month -> prev month)
    await tester.tap(find.text('Kustom'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Akhir'), findsOneWidget);

    await tester.tap(find.text('Akhir'));
    await tester.pumpAndSettle();
    // Step back to previous month and select day 1 (guaranteed earlier than current month 1st)
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('1'),
      ).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tanggal mulai tidak boleh setelah tanggal akhir.'),
      findsWidgets,
    );

    // Pick a valid future End Date (Next month) -> displays future range banner safely
    await tester.tap(find.text('Akhir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('15'),
      ).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tanggal mendatang'), findsOneWidget);

    expect(tester.takeException(), isNull);

    await database.close();
  });
}
