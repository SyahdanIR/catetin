import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dompetku/data/database/app_database.dart';
import 'package:dompetku/data/models/category_model.dart';
import 'package:dompetku/data/models/transaction_model.dart';
import 'package:dompetku/data/repositories/finance_repository.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Phase 1: Local SQLite & Drift Database Tests', () {
    late AppDatabase database;
    late FinanceRepository repository;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      repository = FinanceRepository(database: database);
      await repository.init();
    });

    tearDown(() async {
      await database.close();
    });

    // 1. Insert transaction
    test('1. Insert transaction into database', () async {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'test_tx_1',
        title: 'Beli Buku Pemrograman',
        amount: 150000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        walletId: 'main_wallet',
        transactionDate: now,
        note: 'Buku Dart & Flutter',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addTransaction(tx);
      final persisted = await database.getTransactionById('test_tx_1');
      expect(persisted, isNotNull);
      expect(persisted!.title, 'Beli Buku Pemrograman');
      expect(persisted.amount, 150000);
    });

    // 2. Retrieve transaction
    test('2. Retrieve transaction by ID and in list', () async {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'test_tx_retrieve',
        title: 'Pembayaran Servis Motor',
        amount: 250000,
        type: TransactionType.expense,
        categoryId: 'transport',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addTransaction(tx);
      final retrieved = await database.getTransactionById('test_tx_retrieve');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test_tx_retrieve');
      expect(retrieved.amount, 250000);

      final allTransactions = await database.getAllTransactions();
      expect(allTransactions.any((item) => item.id == 'test_tx_retrieve'), isTrue);
    });

    // 3. Update transaction
    test('3. Update existing transaction details', () async {
      final now = DateTime.now();
      final initialTx = TransactionModel(
        id: 'test_tx_update',
        title: 'Makan Pagi',
        amount: 25000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );
      await repository.addTransaction(initialTx);

      final updatedTx = initialTx.copyWith(
        title: 'Makan Pagi + Jus Buah',
        amount: 40000,
        note: 'Nasi uduk dan jus alpukat',
        updatedAt: now.add(const Duration(minutes: 5)),
      );
      await repository.updateTransaction(updatedTx);

      final found = await database.getTransactionById('test_tx_update');
      expect(found, isNotNull);
      expect(found!.title, 'Makan Pagi + Jus Buah');
      expect(found.amount, 40000);
      expect(found.note, 'Nasi uduk dan jus alpukat');
    });

    // 4. Delete transaction
    test('4. Delete transaction by ID', () async {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'test_tx_delete',
        title: 'Langganan Musik',
        amount: 55000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );
      await repository.addTransaction(tx);
      expect(await database.getTransactionById('test_tx_delete'), isNotNull);

      await repository.deleteTransaction('test_tx_delete');
      final found = await database.getTransactionById('test_tx_delete');
      expect(found, isNull);
      expect(repository.transactions.any((item) => item.id == 'test_tx_delete'), isFalse);
    });

    // 5. Insert income
    test('5. Insert income transaction', () async {
      final now = DateTime.now();
      final incomeTx = TransactionModel(
        id: 'test_tx_income',
        title: 'Gaji Bulanan Tambahan',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addTransaction(incomeTx);
      final found = await database.getTransactionById('test_tx_income');
      expect(found, isNotNull);
      expect(found!.type, TransactionType.income);
      expect(found.amount, 5000000);
    });

    // 6. Insert expense
    test('6. Insert expense transaction', () async {
      final now = DateTime.now();
      final expenseTx = TransactionModel(
        id: 'test_tx_expense',
        title: 'Tagihan Listrik Rumah',
        amount: 350000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addTransaction(expenseTx);
      final found = await database.getTransactionById('test_tx_expense');
      expect(found, isNotNull);
      expect(found!.type, TransactionType.expense);
      expect(found.amount, 350000);
    });

    // 7. Verify balance calculation (Initial + Income - Expense)
    test('7. Verify balance formula: Total Balance = Initial Balance + Total Income - Total Expenses', () async {
      // Clear seeded transactions to test formula deterministically
      final currentList = List<TransactionModel>.from(repository.transactions);
      for (final tx in currentList) {
        await repository.deleteTransaction(tx.id);
      }

      // Initial state: 0
      expect(repository.getTotalBalance(), 0);

      final now = DateTime.now();
      // Add Income: 10,000,000 IDR
      await repository.addTransaction(TransactionModel(
        id: 'calc_inc_1',
        title: 'Pemasukan Gaji',
        amount: 10000000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ));

      // Add Income: 2,500,000 IDR
      await repository.addTransaction(TransactionModel(
        id: 'calc_inc_2',
        title: 'Bonus Proyek',
        amount: 2500000,
        type: TransactionType.income,
        categoryId: 'bonus',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ));

      // Add Expense: 1,500,000 IDR
      await repository.addTransaction(TransactionModel(
        id: 'calc_exp_1',
        title: 'Belanja Bulanan',
        amount: 1500000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ));

      // Add Expense: 500,000 IDR
      await repository.addTransaction(TransactionModel(
        id: 'calc_exp_2',
        title: 'Tagihan Air & Listrik',
        amount: 500000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'main_wallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ));

      // Total Expected = 0 + (10000000 + 2500000) - (1500000 + 500000) = 10,500,000
      const expectedBalance = 10500000;
      expect(repository.getTotalBalance(), expectedBalance);
      expect(repository.getTotalIncome(), 12500000);
      expect(repository.getTotalExpense(), 2000000);
    });

    // 8. Verify monthly income
    test('8. Verify monthly income calculation for target month', () async {
      // Clear seeded data
      final currentList = List<TransactionModel>.from(repository.transactions);
      for (final tx in currentList) {
        await repository.deleteTransaction(tx.id);
      }

      final dateThisMonth = DateTime(2026, 11, 10);
      final dateOtherMonth = DateTime(2026, 10, 15);

      await repository.addTransaction(TransactionModel(
        id: 'inc_nov_1',
        title: 'Gaji November',
        amount: 7000000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: dateThisMonth,
        source: 'manual',
        createdAt: dateThisMonth,
        updatedAt: dateThisMonth,
      ));

      await repository.addTransaction(TransactionModel(
        id: 'inc_nov_2',
        title: 'Bonus November',
        amount: 1000000,
        type: TransactionType.income,
        categoryId: 'bonus',
        walletId: 'main_wallet',
        transactionDate: dateThisMonth,
        source: 'manual',
        createdAt: dateThisMonth,
        updatedAt: dateThisMonth,
      ));

      await repository.addTransaction(TransactionModel(
        id: 'inc_oct_1',
        title: 'Gaji Oktober',
        amount: 6500000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: dateOtherMonth,
        source: 'manual',
        createdAt: dateOtherMonth,
        updatedAt: dateOtherMonth,
      ));

      final monthlyIncome = repository.getMonthlyIncome(DateTime(2026, 11));
      expect(monthlyIncome, 8000000);
    });

    // 9. Verify monthly expenses
    test('9. Verify monthly expenses calculation for target month', () async {
      // Clear seeded data
      final currentList = List<TransactionModel>.from(repository.transactions);
      for (final tx in currentList) {
        await repository.deleteTransaction(tx.id);
      }

      final dateThisMonth = DateTime(2026, 11, 5);
      final dateOtherMonth = DateTime(2026, 10, 20);

      await repository.addTransaction(TransactionModel(
        id: 'exp_nov_1',
        title: 'Makan November',
        amount: 250000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: dateThisMonth,
        source: 'manual',
        createdAt: dateThisMonth,
        updatedAt: dateThisMonth,
      ));

      await repository.addTransaction(TransactionModel(
        id: 'exp_nov_2',
        title: 'Bensin November',
        amount: 150000,
        type: TransactionType.expense,
        categoryId: 'transport',
        walletId: 'main_wallet',
        transactionDate: dateThisMonth,
        source: 'manual',
        createdAt: dateThisMonth,
        updatedAt: dateThisMonth,
      ));

      await repository.addTransaction(TransactionModel(
        id: 'exp_oct_1',
        title: 'Makan Oktober',
        amount: 300000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: dateOtherMonth,
        source: 'manual',
        createdAt: dateOtherMonth,
        updatedAt: dateOtherMonth,
      ));

      final monthlyExpense = repository.getMonthlyExpense(DateTime(2026, 11));
      expect(monthlyExpense, 400000);
    });

    // 10. Verify category relationships
    test('10. Verify category definitions and relationships', () async {
      final categories = await database.getAllCategories();
      expect(categories, isNotEmpty);

      // Check default income categories
      final incomeCatNames = categories
          .where((c) => c.type == CategoryType.income)
          .map((c) => c.name)
          .toList();
      expect(incomeCatNames, containsAll(['Gaji', 'Bonus', 'Bisnis', 'Investasi', 'Pemasukan Lainnya']));

      // Check default expense categories
      final expenseCatNames = categories
          .where((c) => c.type == CategoryType.expense)
          .map((c) => c.name)
          .toList();
      expect(expenseCatNames, containsAll([
        'Makanan & Minuman',
        'Transportasi',
        'Belanja',
        'Hiburan',
        'Tagihan',
        'Kesehatan',
        'Pengeluaran Lainnya'
      ]));

      // Verify transaction resolves category model via repository
      final foodCategory = repository.getCategoryById('food');
      expect(foodCategory, isNotNull);
      expect(foodCategory!.name, 'Makanan & Minuman');
    });

    // 11. Verify default seed data is not duplicated on multiple inits
    test('11. Verify default seed data is not duplicated on multiple inits', () async {
      final initialCategories = await database.getAllCategories();
      final initialWallets = await database.getAllWallets();

      // Trigger re-initialization
      await repository.init();
      await repository.init();

      final reloadedCategories = await database.getAllCategories();
      final reloadedWallets = await database.getAllWallets();

      expect(reloadedCategories.length, initialCategories.length);
      expect(reloadedWallets.length, initialWallets.length);
      expect(reloadedWallets.where((w) => w.name == 'Dompet Utama').length, 1);
    });

    // 12. Verify persistence after closing and reopening a file-backed database using a temporary file
    test('12. Verify persistence across closing and reopening file-backed database', () async {
      final tempDir = Directory.systemTemp.createTempSync('dompetku_persist_test_');
      final dbFile = File(p.join(tempDir.path, 'persisted_dompetku.sqlite'));

      try {
        // Step 1: Open database, initialize repository, write transaction
        final db1 = AppDatabase(NativeDatabase(dbFile));
        final repo1 = FinanceRepository(database: db1);
        await repo1.init();

        final now = DateTime(2026, 11, 9, 14, 0);
        final persistentTx = TransactionModel(
          id: 'tx_persistent_test',
          title: 'Investasi Logam Mulia',
          amount: 1250000,
          type: TransactionType.income,
          categoryId: 'investment',
          walletId: 'main_wallet',
          transactionDate: now,
          note: 'Beli emas antam 1 gram',
          source: 'manual',
          createdAt: now,
          updatedAt: now,
        );
        await repo1.addTransaction(persistentTx);

        // Step 2: Explicitly close first database connection
        await db1.close();

        // Step 3: Reopen database from same file
        final db2 = AppDatabase(NativeDatabase(dbFile));
        final repo2 = FinanceRepository(database: db2);
        await repo2.init();

        // Step 4: Verify transaction persisted
        final recoveredTx = await db2.getTransactionById('tx_persistent_test');
        expect(recoveredTx, isNotNull);
        expect(recoveredTx!.id, 'tx_persistent_test');
        expect(recoveredTx.title, 'Investasi Logam Mulia');
        expect(recoveredTx.amount, 1250000);
        expect(recoveredTx.note, 'Beli emas antam 1 gram');

        await db2.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
