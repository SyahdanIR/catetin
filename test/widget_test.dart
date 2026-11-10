import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catetin/main.dart';
import 'package:catetin/core/theme/app_colors.dart';
import 'package:catetin/core/theme/app_shadows.dart';
import 'package:catetin/core/theme/app_theme.dart';
import 'package:catetin/data/database/app_database.dart';
import 'package:catetin/data/repositories/finance_repository.dart';
import 'package:catetin/features/dashboard/screens/dashboard_screen.dart';
import 'package:catetin/features/dashboard/widgets/expense_pie_chart_card.dart';
import 'package:catetin/features/dashboard/widgets/recent_transactions_section.dart';
import 'package:catetin/features/receipt_scanner/screens/receipt_scanner_screen.dart';
import 'package:catetin/features/transactions/widgets/transaction_filter_bar.dart';
import 'package:catetin/features/transactions/widgets/transaction_tile.dart';
import 'package:catetin/data/models/transaction_model.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('Catetin smoke test - dashboard renders greeting and tabs',
      (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();
    await tester.pumpWidget(CatetinApp(repository: repository));

    // Verify personalized greeting renders
    expect(find.text('Halo, Syahdan!'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Scan Struk'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    await database.close();
  });

  testWidgets('ReceiptScannerScreen review buttons render without overflow on 360px screen',
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
        home: ReceiptScannerScreen(
          repository: repository,
          onSaved: () {},
        ),
      ),
    );

    // Tap the camera capture button to trigger mock OCR scan
    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pump();
    // Wait for 1400ms simulated OCR timer to transition to review step
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Hasil Ekstraksi Struk'), findsOneWidget);
    expect(find.text('Pindai Ulang'), findsOneWidget);
    expect(find.text('Simpan ke Dompet'), findsOneWidget);
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

  testWidgets('TransactionTile displays negative sign for expenses and positive sign for income',
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
      'DashboardScreen renders pie chart cards and single-box 3 recent transactions on 360px screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();

    // Add a current-week expense so both pie chart cards render slices
    final now = DateTime.now();
    await repository.addTransaction(
      TransactionModel(
        id: 'tx_week_test_1',
        title: 'Makan Siang Minggu Ini',
        amount: 45000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    int? navigatedTab;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: DashboardScreen(
          repository: repository,
          onNavigateTab: (tab) => navigatedTab = tab,
          onQuickAdd: (_) {},
          onEditTransaction: (_) {},
        ),
      ),
    );

    expect(find.byType(ExpensePieChartCard), findsNWidgets(2));
    expect(find.text('Pengeluaran Minggu Ini'), findsOneWidget);
    expect(find.text('Pengeluaran by Kategori'), findsOneWidget);

    // RecentTransactionsSection must show only 3 most recent items
    expect(find.byType(RecentTransactionsSection), findsOneWidget);
    expect(find.text('Transaksi Terkini'), findsOneWidget);
    expect(find.text('Lihat Semua'), findsOneWidget);

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

    // 4th oldest transaction ('Belanja Mingguan Supermarket' / 'Gaji Bulanan') should not appear in RecentTransactionsSection
    final allTxs = repository.transactions;
    expect(allTxs.length, greaterThan(3));
    expect(
      find.descendant(
        of: find.byType(RecentTransactionsSection),
        matching: find.text(allTxs.last.title),
      ),
      findsNothing,
    );

    // Scroll to and tap Lihat Semua -> navigates to Transactions tab (3)
    await tester.ensureVisible(find.text('Lihat Semua'));
    await tester.tap(find.text('Lihat Semua'));
    await tester.pumpAndSettle();
    expect(navigatedTab, 3);

    // Period dropdown in Pengeluaran by Kategori switches period cleanly
    await tester.ensureVisible(find.text('Bulan Ini'));
    await tester.tap(find.text('Bulan Ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 Tahun Terakhir'));
    await tester.pumpAndSettle();
    expect(find.text('1 Tahun'), findsOneWidget);

    // Tapping a category legend row opens detail bottom sheet
    await tester.tap(
      find.descendant(
        of: find.byType(ExpensePieChartCard).last,
        matching: find.text('Belanja'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belanja Mingguan Supermarket'), findsOneWidget);
    Navigator.of(tester.element(find.text('Belanja Mingguan Supermarket'))).pop();
    await tester.pumpAndSettle();

    // Tapping a recent transaction row opens detail sheet with Ubah & Hapus
    await tester.ensureVisible(find.text(recentTxs.first.title));
    await tester.tap(
      find.descendant(
        of: find.byType(RecentTransactionsSection),
        matching: find.text(recentTxs.first.title),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ubah'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
    Navigator.of(tester.element(find.text('Ubah'))).pop();
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
}
