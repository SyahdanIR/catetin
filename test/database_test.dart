import 'dart:async';
import 'dart:io';

import 'package:catetin/core/utils/currency_formatter.dart';
import 'package:catetin/core/utils/date_formatter.dart';
import 'package:catetin/data/database/app_database.dart';
import 'package:catetin/data/models/category_model.dart';
import 'package:catetin/data/models/transaction_model.dart';
import 'package:catetin/data/models/wallet_model.dart';
import 'package:catetin/data/repositories/finance_repository.dart';
import 'package:drift/drift.dart'
    show GeneratedDatabase, MigrationStrategy, Table, TableInfo, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _CountingAppDatabase extends AppDatabase {
  int getTransactionsCalls = 0;
  int getWalletsCalls = 0;
  int getCategoriesCalls = 0;
  Completer<void>? barrier;

  _CountingAppDatabase(super.e);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    getTransactionsCalls++;
    if (barrier != null) {
      await barrier!.future;
    }
    return super.getAllTransactions();
  }

  @override
  Future<List<WalletModel>> getAllWallets() async {
    getWalletsCalls++;
    return super.getAllWallets();
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    getCategoriesCalls++;
    return super.getAllCategories();
  }
}

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
  Future<void> updateTransactionRow(TransactionModel tx) async {
    if (failWrites) {
      throw StateError('Simulated SQLite update failure');
    }
    return super.updateTransactionRow(tx);
  }

  @override
  Future<void> deleteTransactionRow(String id) async {
    if (failWrites) {
      throw StateError('Simulated SQLite delete failure');
    }
    return super.deleteTransactionRow(id);
  }
}

class _V1LegacyDatabase extends GeneratedDatabase {
  _V1LegacyDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement('''
            CREATE TABLE wallets (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              initial_balance INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            );
          ''');
          await customStatement('''
            CREATE TABLE categories (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              icon_code_point INTEGER NOT NULL,
              color_value INTEGER NOT NULL,
              bg_color_value INTEGER NOT NULL
            );
          ''');
          await customStatement('''
            CREATE TABLE transactions (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              type TEXT NOT NULL,
              amount INTEGER NOT NULL,
              category_id TEXT NOT NULL REFERENCES categories (id),
              wallet_id TEXT NOT NULL REFERENCES wallets (id),
              transaction_date INTEGER NOT NULL,
              note TEXT NULL,
              source TEXT NOT NULL DEFAULT 'manual',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              is_recurring INTEGER NOT NULL DEFAULT 0
            );
          ''');

          await customStatement(
            "INSERT INTO wallets (id, name, initial_balance, created_at) "
            "VALUES ('main_wallet', 'Dompet Utama', 1000000, 1767225600);",
          );
          await customStatement(
            "INSERT INTO categories (id, name, type, icon_code_point, color_value, bg_color_value) "
            "VALUES ('food', 'Makanan & Minuman', 'expense', 58732, 4293467747, 4294959835);",
          );
          // Legacy v1 row pointing to bank_bca before wallets table contained bank_bca
          await customStatement(
            "INSERT INTO transactions (id, title, type, amount, category_id, wallet_id, transaction_date, note, source, created_at, updated_at, is_recurring) "
            "VALUES ('v1_tx_1', 'Kopi V1 BCA', 'expense', 45000, 'food', 'bank_bca', 1794000000, 'Migrasi v1', 'manual', 1794000000, 1794000000, 0);",
          );
        },
      );
}

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

    test('1. Empty database initialization starts with 0 transactions and Rp 0 balance', () async {
      expect(repository.isInitialized, isTrue);
      expect(repository.transactions, isEmpty);
      expect(await database.getAllTransactions(), isEmpty);
      expect(repository.getTotalBalance(), 0);
      expect(repository.getTotalIncome(), 0);
      expect(repository.getTotalExpense(), 0);
    });

    test('2. Default wallets are seeded in SQLite matching selectable UI options', () async {
      final dbWallets = await database.getAllWallets();
      expect(dbWallets.length, 3);
      expect(
        dbWallets.map((w) => w.id),
        containsAll(['main_wallet', 'bank_bca', 'ewallet']),
      );
      expect(repository.wallets.length, 3);
      expect(repository.getWalletById('main_wallet')?.name, 'Dompet Utama');
      expect(repository.getWalletById('bank_bca')?.name, 'Rekening Bank');
      expect(repository.getWalletById('ewallet')?.name, 'E-Wallet');
    });

    test('3. Default categories are seeded without duplication across repeated inits', () async {
      final initialCategories = await database.getAllCategories();
      final initialWallets = await database.getAllWallets();

      expect(initialCategories.length, CategoryModel.defaultCategories.length);

      final incomeCatNames = initialCategories
          .where((c) => c.type == CategoryType.income)
          .map((c) => c.name)
          .toList();
      expect(
        incomeCatNames,
        containsAll(['Gaji', 'Bonus', 'Bisnis', 'Investasi', 'Pemasukan Lainnya']),
      );

      final expenseCatNames = initialCategories
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
        'Pengeluaran Lainnya',
      ]));

      await repository.init();
      await repository.refresh();

      expect((await database.getAllCategories()).length, initialCategories.length);
      expect((await database.getAllWallets()).length, initialWallets.length);
    });

    test('4. SQLite foreign keys are enabled and reject invalid walletId or categoryId', () async {
      expect(await database.areForeignKeysEnabled(), isTrue);

      final now = DateTime(2026, 11, 10, 12, 0);
      final badWalletTx = TransactionModel(
        id: 'tx_bad_wallet',
        title: 'Invalid Wallet Ref',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'nonexistent_wallet',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await expectLater(
        repository.addTransaction(badWalletTx),
        throwsA(isA<SqliteException>()),
      );
      expect(repository.transactions, isEmpty);

      final badCategoryTx = badWalletTx.copyWith(
        id: 'tx_bad_cat',
        walletId: 'main_wallet',
        categoryId: 'nonexistent_category',
      );
      await expectLater(
        repository.addTransaction(badCategoryTx),
        throwsA(isA<SqliteException>()),
      );
      expect(repository.transactions, isEmpty);
    });

    test('5. Add income transaction and verify persistence', () async {
      final now = DateTime(2026, 11, 10, 9, 0);
      final incomeTx = TransactionModel(
        id: 'test_tx_income',
        title: 'Gaji Bulanan',
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
      expect(repository.getTotalBalance(), 5000000);
    });

    test('6. Add expense transaction and verify persistence across all default wallets', () async {
      final now = DateTime(2026, 11, 10, 13, 0);
      final expenseTx = TransactionModel(
        id: 'test_tx_expense',
        title: 'Belanja QRIS',
        amount: 350000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'ewallet',
        transactionDate: now,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addTransaction(expenseTx);
      final found = await database.getTransactionById('test_tx_expense');
      expect(found, isNotNull);
      expect(found!.type, TransactionType.expense);
      expect(found.walletId, 'ewallet');
      expect(found.amount, 350000);
      expect(repository.getBalanceForWallet('ewallet'), -350000);
    });

    test('7. Update transaction reflects in SQLite and repository', () async {
      final now = DateTime(2026, 11, 10, 8, 0);
      final initialTx = TransactionModel(
        id: 'test_tx_update',
        title: 'Makan Pagi',
        amount: 25000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await repository.addTransaction(initialTx);

      final updatedTx = initialTx.copyWith(
        title: 'Makan Pagi + Jus Buah',
        amount: 40000,
        walletId: 'bank_bca',
        note: 'Nasi uduk dan jus alpukat',
        updatedAt: now.add(const Duration(minutes: 5)),
      );
      await repository.updateTransaction(updatedTx);

      final found = await database.getTransactionById('test_tx_update');
      expect(found, isNotNull);
      expect(found!.title, 'Makan Pagi + Jus Buah');
      expect(found.amount, 40000);
      expect(found.walletId, 'bank_bca');
      expect(found.note, 'Nasi uduk dan jus alpukat');
    });

    test('8. Delete transaction removes record from SQLite and repository', () async {
      final now = DateTime(2026, 11, 10, 10, 0);
      final tx = TransactionModel(
        id: 'test_tx_delete',
        title: 'Langganan Musik',
        amount: 55000,
        type: TransactionType.expense,
        categoryId: 'bills',
        walletId: 'main_wallet',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await repository.addTransaction(tx);
      expect(await database.getTransactionById('test_tx_delete'), isNotNull);

      await repository.deleteTransaction('test_tx_delete');
      expect(await database.getTransactionById('test_tx_delete'), isNull);
      expect(repository.transactions, isEmpty);
    });

    test('9 & 10. Scenarios A-D: balance and monthly totals recalculate accurately after edit and delete', () async {
      final month = DateTime(2026, 11, 10);
      expect(repository.getTotalBalance(), 0);

      // Scenario A: Add income Rp5.000.000 -> Rp5.000.000
      await repository.addTransaction(TransactionModel(
        id: 'sc_inc',
        title: 'Gaji Bulan Ini',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: month,
        createdAt: month,
        updatedAt: month,
      ));
      expect(repository.getTotalBalance(), 5000000);
      expect(repository.getMonthlyIncome(month), 5000000);
      expect(repository.getMonthlyExpense(month), 0);
      expect(repository.getMonthlyNetBalance(month), 5000000);

      // Scenario B: Add expense Rp50.000 -> Rp4.950.000
      final expenseTx = TransactionModel(
        id: 'sc_exp',
        title: 'Makan Siang',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: month,
        createdAt: month,
        updatedAt: month,
      );
      await repository.addTransaction(expenseTx);
      expect(repository.getTotalBalance(), 4950000);
      expect(repository.getMonthlyIncome(month), 5000000);
      expect(repository.getMonthlyExpense(month), 50000);
      expect(repository.getMonthlyNetBalance(month), 4950000);

      // Scenario C: Edit expense to Rp75.000 -> Rp4.925.000
      await repository.updateTransaction(expenseTx.copyWith(amount: 75000));
      expect(repository.getTotalBalance(), 4925000);
      expect(repository.getMonthlyIncome(month), 5000000);
      expect(repository.getMonthlyExpense(month), 75000);
      expect(repository.getMonthlyNetBalance(month), 4925000);

      // Scenario D: Delete the expense -> Rp5.000.000
      await repository.deleteTransaction('sc_exp');
      expect(repository.getTotalBalance(), 5000000);
      expect(repository.getMonthlyIncome(month), 5000000);
      expect(repository.getMonthlyExpense(month), 0);
      expect(repository.getMonthlyNetBalance(month), 5000000);
    });

    test('11 & 12. Monthly income/expense, daily net balance, and wallet filtering work accurately', () async {
      final nov10 = DateTime(2026, 11, 10, 12, 0);
      final oct15 = DateTime(2026, 10, 15, 12, 0);

      await repository.addTransaction(TransactionModel(
        id: 'm_inc_main',
        title: 'Gaji Utama',
        amount: 7000000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: nov10,
        createdAt: nov10,
        updatedAt: nov10,
      ));
      await repository.addTransaction(TransactionModel(
        id: 'm_exp_main',
        title: 'Makan Siang',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: nov10,
        createdAt: nov10,
        updatedAt: nov10,
      ));
      await repository.addTransaction(TransactionModel(
        id: 'm_exp_bca',
        title: 'Bensin BCA',
        amount: 250000,
        type: TransactionType.expense,
        categoryId: 'transport',
        walletId: 'bank_bca',
        transactionDate: nov10,
        createdAt: nov10,
        updatedAt: nov10,
      ));
      await repository.addTransaction(TransactionModel(
        id: 'm_oct_bca',
        title: 'Transfer Masuk Oktober',
        amount: 1000000,
        type: TransactionType.income,
        categoryId: 'business',
        walletId: 'bank_bca',
        transactionDate: oct15,
        createdAt: oct15,
        updatedAt: oct15,
      ));

      expect(repository.getMonthlyIncome(nov10), 7000000);
      expect(repository.getMonthlyExpense(nov10), 350000);
      expect(repository.getMonthlyNetBalance(nov10), 6650000);

      expect(repository.getMonthlyIncome(nov10, walletId: 'bank_bca'), 0);
      expect(repository.getMonthlyExpense(nov10, walletId: 'bank_bca'), 250000);
      expect(repository.getMonthlyNetBalance(nov10, walletId: 'bank_bca'), -250000);
      expect(repository.getBalanceForWallet('bank_bca'), 750000);
      expect(repository.getBalanceForWallet('main_wallet'), 6900000);
      expect(repository.getTotalBalance(), 7650000);

      expect(repository.getDailyNetBalance(nov10), 6650000);
      expect(repository.getDailyNetBalance(nov10, walletId: 'bank_bca'), -250000);

      final bcaHistory = repository.getTransactionsForPeriod(walletId: 'bank_bca');
      expect(bcaHistory.length, 2);
      expect(bcaHistory.every((t) => t.walletId == 'bank_bca'), isTrue);

      expect(
        repository.getCategoryExpenseBreakdown(nov10, walletId: 'main_wallet'),
        {'food': 100000},
      );
      expect(
        repository.getCategoryExpenseBreakdown(nov10),
        {'food': 100000, 'transport': 250000},
      );
    });

    test('13. CurrencyFormatter formats negative, zero, and signed IDR amounts without extra spaces', () {
      expect(CurrencyFormatter.format(50000), 'Rp 50.000');
      expect(CurrencyFormatter.format(-50000), '-Rp 50.000');
      expect(CurrencyFormatter.format(0), 'Rp 0');
      expect(CurrencyFormatter.format(-50000, includeSymbol: false), '-50.000');
      expect(CurrencyFormatter.format(-385000, withSign: true), '- Rp 385.000');
      expect(CurrencyFormatter.format(2800000, withSign: true), '+ Rp 2.800.000');
    });

    test('14. Date range boundaries use exclusive next-day cutoff and Feb 29 leap-day subtraction stays in February', () async {
      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 10);

      // Note: Drift NativeDatabase stores DateTime at second precision (truncating .999 to .000),
      // while startDate <= transactionDate < dayAfterEndDate holds strictly at both boundaries.
      await repository.addTransaction(TransactionModel(
        id: 'b_end_235959',
        title: 'Transaksi Menit Terakhir',
        amount: 120000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        transactionDate: DateTime(2026, 11, 10, 23, 59, 59, 999),
        createdAt: start,
        updatedAt: start,
      ));
      await repository.addTransaction(TransactionModel(
        id: 'b_next_midnight',
        title: 'Transaksi Hari Berikutnya',
        amount: 300000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        walletId: 'main_wallet',
        transactionDate: DateTime(2026, 11, 11, 0, 0, 0),
        createdAt: start,
        updatedAt: start,
      ));
      await repository.addTransaction(TransactionModel(
        id: 'b_inc_end',
        title: 'Pemasukan Menit Terakhir',
        amount: 500000,
        type: TransactionType.income,
        categoryId: 'bonus',
        walletId: 'main_wallet',
        transactionDate: DateTime(2026, 11, 10, 23, 59, 59),
        createdAt: start,
        updatedAt: start,
      ));

      expect(repository.getPeriodExpense(start, end), 120000);
      expect(repository.getPeriodIncome(start, end), 500000);
      expect(repository.getPeriodNetBalance(start, end), 380000);
      expect(repository.getCategoryExpenseBreakdownForPeriod(start, end), {'food': 120000});

      final inRange = repository.getTransactionsForDateRange(start: start, end: end);
      expect(inRange.map((t) => t.id), containsAll(['b_end_235959', 'b_inc_end']));
      expect(inRange.map((t) => t.id), isNot(contains('b_next_midnight')));

      // Leap day check: 2024-02-29 minus 1 year must be 2023-02-28 (never March 1)
      expect(
        AppDateFormatter.subtractOneYear(DateTime(2024, 2, 29)),
        DateTime(2023, 2, 28),
      );
      expect(
        AppDateFormatter.subtractOneYear(DateTime(2025, 2, 28)),
        DateTime(2024, 2, 28),
      );
    });

    test('15 & 16. File-backed persistence across restart preserves inserts, updates, deletes, and never re-seeds empty ledger', () async {
      final tempDir = Directory.systemTemp.createTempSync('catetin_persist_full_');
      final dbFile = File(p.join(tempDir.path, 'persisted_catetin.sqlite'));

      try {
        // Session 1: fresh DB must stay empty (0 mock transactions), then insert two items
        final db1 = AppDatabase(NativeDatabase(dbFile));
        final repo1 = FinanceRepository(database: db1);
        await repo1.init();
        expect(repo1.transactions, isEmpty);

        final txDate = DateTime(2026, 11, 9, 14, 0);
        await repo1.addTransaction(TransactionModel(
          id: 'tx_p_1',
          title: 'Investasi Emas',
          amount: 1250000,
          type: TransactionType.income,
          categoryId: 'investment',
          walletId: 'main_wallet',
          transactionDate: txDate,
          createdAt: txDate,
          updatedAt: txDate,
        ));
        await repo1.addTransaction(TransactionModel(
          id: 'tx_p_2',
          title: 'Kopi Pagi',
          amount: 25000,
          type: TransactionType.expense,
          categoryId: 'food',
          walletId: 'bank_bca',
          transactionDate: txDate,
          createdAt: txDate,
          updatedAt: txDate,
        ));
        await db1.close();

        // Session 2: reopen, verify both exist, update tx_p_1, delete tx_p_2
        final db2 = AppDatabase(NativeDatabase(dbFile));
        final repo2 = FinanceRepository(database: db2);
        await repo2.init();
        expect(repo2.transactions.length, 2);
        expect(repo2.getTotalBalance(), 1225000);

        final tx1 = repo2.transactions.firstWhere((t) => t.id == 'tx_p_1');
        await repo2.updateTransaction(tx1.copyWith(amount: 1500000, title: 'Investasi Emas Updated'));
        await repo2.deleteTransaction('tx_p_2');
        await db2.close();

        // Session 3: reopen, verify update + delete survived, then delete remaining tx_p_1
        final db3 = AppDatabase(NativeDatabase(dbFile));
        final repo3 = FinanceRepository(database: db3);
        await repo3.init();
        expect(repo3.transactions.length, 1);
        expect(repo3.transactions.first.title, 'Investasi Emas Updated');
        expect(repo3.transactions.first.amount, 1500000);
        expect(repo3.getTotalBalance(), 1500000);

        await repo3.deleteTransaction('tx_p_1');
        expect(repo3.transactions, isEmpty);
        await db3.close();

        // Session 4: reopen empty DB; must remain empty and NEVER re-seed tx_1..tx_6
        final db4 = AppDatabase(NativeDatabase(dbFile));
        final repo4 = FinanceRepository(database: db4);
        await repo4.init();
        expect(repo4.transactions, isEmpty);
        expect(await db4.getAllTransactions(), isEmpty);
        expect(repo4.getTotalBalance(), 0);
        await db4.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('17. Concurrent FinanceRepository.init() calls deduplicate into a single DB initialization', () async {
      final spyDb = _CountingAppDatabase(NativeDatabase.memory());
      spyDb.barrier = Completer<void>();
      final spyRepo = FinanceRepository(database: spyDb);

      // Constructor must NOT trigger unawaited init()
      await Future<void>.delayed(Duration.zero);
      expect(spyDb.getTransactionsCalls, 0);

      final futures = [spyRepo.init(), spyRepo.init(), spyRepo.init()];
      spyDb.barrier!.complete();
      await Future.wait(futures);

      expect(spyDb.getTransactionsCalls, 1);
      expect(spyDb.getWalletsCalls, 1);
      expect(spyDb.getCategoriesCalls, 1);

      // Subsequent init() calls after completion remain no-ops
      await spyRepo.init();
      expect(spyDb.getTransactionsCalls, 1);

      await spyDb.close();
    });

    test('18. Failed database write operations preserve state, set errorMessage, and rethrow', () async {
      final failDb = _FailingWriteAppDatabase(NativeDatabase.memory())..failWrites = false;
      final failRepo = FinanceRepository(database: failDb);
      await failRepo.init();

      final now = DateTime(2026, 11, 10);
      final existing = TransactionModel(
        id: 'existing_1',
        title: 'Existing',
        amount: 100000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await failRepo.addTransaction(existing);

      failDb.failWrites = true;

      await expectLater(
        failRepo.addTransaction(existing.copyWith(id: 'new_fail', amount: 50000)),
        throwsA(isA<StateError>()),
      );
      expect(failRepo.errorMessage, isNotNull);
      expect(failRepo.isLoading, isFalse);
      expect(failRepo.transactions.length, 1);
      expect(failRepo.getTotalBalance(), 100000);

      await expectLater(
        failRepo.updateTransaction(existing.copyWith(amount: 999999)),
        throwsA(isA<StateError>()),
      );
      expect(failRepo.transactions.first.amount, 100000);

      await expectLater(
        failRepo.deleteTransaction('existing_1'),
        throwsA(isA<StateError>()),
      );
      expect(failRepo.transactions.length, 1);

      await failDb.close();
    });

    test('19. Schema v1 to v2 migration preserves user data and seeds bank_bca/ewallet before enabling FKs', () async {
      final tempDir = Directory.systemTemp.createTempSync('catetin_migrate_v1_v2_');
      final dbFile = File(p.join(tempDir.path, 'v1_upgrade.sqlite'));

      try {
        final v1Db = _V1LegacyDatabase(NativeDatabase(dbFile));
        await v1Db.customSelect('SELECT count(*) AS c FROM transactions').getSingle();
        await v1Db.close();

        // Reopen with v2 AppDatabase -> executes onUpgrade(1 -> 2) and beforeOpen
        final v2Db = AppDatabase(NativeDatabase(dbFile));
        final v2Repo = FinanceRepository(database: v2Db);
        await v2Repo.init();

        expect(await v2Db.areForeignKeysEnabled(), isTrue);
        expect(v2Repo.wallets.length, 3);
        final mainWallet = v2Repo.getWalletById('main_wallet')!;
        expect(mainWallet.initialBalance, 1000000);
        expect(v2Repo.getWalletById('bank_bca'), isNotNull);
        expect(v2Repo.getWalletById('ewallet'), isNotNull);

        expect(v2Repo.transactions.length, 1);
        expect(v2Repo.transactions.first.id, 'v1_tx_1');
        expect(v2Repo.getTotalBalance(), 955000);

        await v2Db.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });

  group('Phase 2: Financial Reports Tests', () {
    late AppDatabase database;
    late FinanceRepository repository;

    Future<void> seedTx({
      required String id,
      required String title,
      required int amount,
      required TransactionType type,
      required String categoryId,
      String walletId = 'main_wallet',
      required DateTime date,
    }) async {
      await repository.addTransaction(
        TransactionModel(
          id: id,
          title: title,
          amount: amount,
          type: type,
          categoryId: categoryId,
          walletId: walletId,
          transactionDate: date,
          createdAt: date,
          updatedAt: date,
        ),
      );
    }

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      repository = FinanceRepository(database: database);
      await repository.init();
    });

    tearDown(() async {
      await database.close();
    });

    test('1-3 & 9-10. Monthly income, expense, net cash flow, and expense-only category percentages', () async {
      await seedTx(
        id: 'm_inc_1',
        title: 'Gaji November',
        amount: 6000000,
        type: TransactionType.income,
        categoryId: 'salary',
        date: DateTime(2026, 11, 1, 8, 0),
      );
      await seedTx(
        id: 'm_inc_2',
        title: 'Bonus Project',
        amount: 2000000,
        type: TransactionType.income,
        categoryId: 'bonus',
        date: DateTime(2026, 11, 15, 19, 30),
      );
      await seedTx(
        id: 'm_exp_food',
        title: 'Makan Malam',
        amount: 1500000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 11, 10, 20, 0),
      );
      await seedTx(
        id: 'm_exp_bills',
        title: 'Listrik & Internet',
        amount: 500000,
        type: TransactionType.expense,
        categoryId: 'bills',
        date: DateTime(2026, 11, 30, 23, 59, 59),
      );
      // Transaction in December must be excluded from November
      await seedTx(
        id: 'm_dec_exclude',
        title: 'Kopi Desember',
        amount: 300000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 12, 1, 0, 0, 0),
      );

      final report = repository.getMonthlyReport(2026, 11);
      final s = report.summary;

      expect(s.totalIncome, 8000000);
      expect(s.totalExpense, 2000000);
      expect(s.netCashFlow, 6000000);
      expect(s.incomeCount, 2);
      expect(s.expenseCount, 2);
      expect(s.averageExpense, 1000000.0);
      expect(s.savingRatePercent, closeTo(75.0, 0.001));
      expect(s.incomeToExpenseRatio, closeTo(4.0, 0.001));

      // Income categories ('salary', 'bonus') must never appear in expense breakdown
      expect(s.categoryBreakdown.keys.toList(), ['food', 'bills']);
      expect(s.categoryBreakdown['food'], 1500000);
      expect(s.categoryBreakdown['bills'], 500000);
      expect(s.categoryItems.length, 2);
      expect(s.categoryItems[0].categoryId, 'food');
      expect(s.categoryItems[0].percentage, closeTo(75.0, 0.001));
      expect(s.categoryItems[1].categoryId, 'bills');
      expect(s.categoryItems[1].percentage, closeTo(25.0, 0.001));
      expect(s.topExpenseCategory?.categoryId, 'food');
      expect(report.trend.length, 4);
      expect(report.trend.fold<int>(0, (sum, p) => sum + p.expense), 2000000);
    });

    test('4. Quarterly aggregation (Q1-Q4) and cross-year navigation', () async {
      // Q4 2025 boundary + Q1 2026 (Jan, Feb, Mar) + Q2 2026 boundary
      await seedTx(
        id: 'q4_dec',
        title: 'Belanja Des 2025',
        amount: 400000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        date: DateTime(2025, 12, 31, 23, 59, 59),
      );
      await seedTx(
        id: 'q1_jan_inc',
        title: 'Gaji Jan',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'salary',
        date: DateTime(2026, 1, 1, 0, 0, 0),
      );
      await seedTx(
        id: 'q1_jan_exp',
        title: 'Makan Jan',
        amount: 1000000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 1, 20),
      );
      // February 2026 intentionally empty (0 tx)
      await seedTx(
        id: 'q1_mar_inc',
        title: 'Bonus Mar',
        amount: 2000000,
        type: TransactionType.income,
        categoryId: 'bonus',
        date: DateTime(2026, 3, 10),
      );
      await seedTx(
        id: 'q1_mar_exp',
        title: 'Transport Mar',
        amount: 2500000,
        type: TransactionType.expense,
        categoryId: 'transport',
        date: DateTime(2026, 3, 31, 23, 59, 59),
      );
      await seedTx(
        id: 'q2_apr_exp',
        title: 'Belanja Apr',
        amount: 900000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        date: DateTime(2026, 4, 1, 0, 0, 0),
      );

      final q1 = repository.getQuarterlyReport(2026, 1);
      expect(q1.summary.totalIncome, 7000000);
      expect(q1.summary.totalExpense, 3500000);
      expect(q1.summary.netCashFlow, 3500000);
      expect(q1.monthlyTrend.length, 3);
      expect(q1.monthlyTrend.map((m) => m.label).toList(), ['Jan', 'Feb', 'Mar']);
      expect(q1.monthlyTrend[0].income, 5000000);
      expect(q1.monthlyTrend[0].expense, 1000000);
      expect(q1.monthlyTrend[1].income, 0);
      expect(q1.monthlyTrend[1].expense, 0);
      expect(q1.monthlyTrend[2].income, 2000000);
      expect(q1.monthlyTrend[2].expense, 2500000);
      expect(q1.highestSpendingMonth?.label, 'Mar');
      expect(q1.comparison.previousSummary.totalExpense, 400000);

      final q2 = repository.getQuarterlyReport(2026, 2);
      expect(q2.summary.totalExpense, 900000);

      expect(FinanceRepository.stepQuarter(2026, 1, -1), (year: 2025, quarter: 4));
      expect(FinanceRepository.stepQuarter(2025, 4, 1), (year: 2026, quarter: 1));
    });

    test('5 & 6. Yearly aggregation produces all 12 months including zero months and accurate high/low months', () async {
      await seedTx(
        id: 'y_jan_inc',
        title: 'Gaji Jan',
        amount: 12000000,
        type: TransactionType.income,
        categoryId: 'salary',
        date: DateTime(2026, 1, 5),
      );
      await seedTx(
        id: 'y_feb_exp',
        title: 'Transport Feb',
        amount: 300000,
        type: TransactionType.expense,
        categoryId: 'transport',
        date: DateTime(2026, 2, 14),
      );
      await seedTx(
        id: 'y_agu_exp',
        title: 'Kesehatan Agu',
        amount: 2400000,
        type: TransactionType.expense,
        categoryId: 'health',
        date: DateTime(2026, 8, 17),
      );
      await seedTx(
        id: 'y_nov_exp',
        title: 'Belanja Nov',
        amount: 900000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        date: DateTime(2026, 11, 25),
      );

      final yearly = repository.getYearlyReport(2026);
      expect(yearly.summary.totalIncome, 12000000);
      expect(yearly.summary.totalExpense, 3600000);
      expect(yearly.summary.netCashFlow, 8400000);
      expect(yearly.averageMonthlyExpense, 300000.0);
      expect(yearly.monthlyTrend.length, 12);
      expect(
        yearly.monthlyTrend.map((m) => m.label).toList(),
        ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'],
      );
      expect(yearly.monthlyTrend[0].income, 12000000);
      expect(yearly.monthlyTrend[0].expense, 0);
      expect(yearly.monthlyTrend[1].expense, 300000);
      expect(yearly.monthlyTrend[7].expense, 2400000);
      expect(yearly.monthlyTrend[10].expense, 900000);
      expect(yearly.monthlyTrend[11].expense, 0);

      expect(yearly.highestSpendingMonth?.label, 'Agu');
      expect(yearly.highestSpendingMonth?.expense, 2400000);
      expect(yearly.lowestSpendingMonth?.label, 'Feb');
      expect(yearly.lowestSpendingMonth?.expense, 300000);
    });

    test('7 & 8. Custom date range validation, inclusive end-date, and trend grouping', () async {
      // Invalid inverted range throws ArgumentError and returns validation message
      expect(
        FinanceRepository.validateCustomDateRange(
          DateTime(2026, 11, 15),
          DateTime(2026, 11, 10),
        ),
        isNotNull,
      );
      expect(
        () => repository.getReportSummary(
          startDate: DateTime(2026, 11, 15),
          endDate: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );

      // Same-day range valid even with non-midnight time components
      expect(
        FinanceRepository.validateCustomDateRange(
          DateTime(2026, 11, 10, 20, 0),
          DateTime(2026, 11, 10, 8, 0),
        ),
        isNull,
      );

      await seedTx(
        id: 'c_before',
        title: 'Sebelum Start',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 10, 31, 23, 59, 59),
      );
      await seedTx(
        id: 'c_start',
        title: 'Tepat Start',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2026, 11, 1, 0, 0, 0),
      );
      await seedTx(
        id: 'c_end',
        title: 'Akhir Hari End',
        amount: 250000,
        type: TransactionType.income,
        categoryId: 'bonus',
        date: DateTime(2026, 11, 5, 23, 59, 59),
      );
      await seedTx(
        id: 'c_after',
        title: 'Hari Setelah End',
        amount: 999000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        date: DateTime(2026, 11, 6, 0, 0, 0),
      );

      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 5);
      final summary = repository.getReportSummary(startDate: start, endDate: end);
      expect(summary.dayCount, 5);
      expect(summary.totalIncome, 250000);
      expect(summary.totalExpense, 100000);
      expect(summary.netCashFlow, 150000);

      final dailyTrend = repository.getIncomeExpenseTrend(
        startDate: start,
        endDate: end,
        granularity: ReportPeriod.custom,
      );
      expect(dailyTrend.length, 5);
      expect(dailyTrend.first.expense, 100000);
      expect(dailyTrend.last.income, 250000);

      // Multi-month custom (> 92 days) uses monthly buckets clamped cleanly
      final longTrend = repository.getIncomeExpenseTrend(
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 11, 20),
        granularity: ReportPeriod.custom,
      );
      expect(longTrend.length, 4);
      expect(longTrend.first.startDate, DateTime(2026, 8, 15));
      expect(longTrend.last.endDate, DateTime(2026, 11, 20));
    });

    test('11 & 12. Empty-period and zero-expense periods produce null/safe metrics with no NaN or Infinity', () async {
      // Completely empty month
      final emptyReport = repository.getMonthlyReport(2026, 6);
      expect(emptyReport.summary.hasAnyTransactions, isFalse);
      expect(emptyReport.summary.totalIncome, 0);
      expect(emptyReport.summary.totalExpense, 0);
      expect(emptyReport.summary.netCashFlow, 0);
      expect(emptyReport.summary.averageExpense, isNull);
      expect(emptyReport.summary.incomeToExpenseRatio, isNull);
      expect(emptyReport.summary.savingRatePercent, isNull);
      expect(emptyReport.summary.categoryItems, isEmpty);
      expect(emptyReport.comparison.expenseChangePercent, isNull);

      // Year with 0 transactions still returns 12 zeroed months and null high/low
      final emptyYear = repository.getYearlyReport(2026);
      expect(emptyYear.monthlyTrend.length, 12);
      expect(emptyYear.highestSpendingMonth, isNull);
      expect(emptyYear.lowestSpendingMonth, isNull);

      // Income-only month (zero expense): no divide-by-zero NaN/Infinity
      await seedTx(
        id: 'inc_only',
        title: 'Gaji Saja',
        amount: 4500000,
        type: TransactionType.income,
        categoryId: 'salary',
        date: DateTime(2026, 7, 10),
      );
      final incomeOnly = repository.getMonthlyReport(2026, 7);
      expect(incomeOnly.summary.totalIncome, 4500000);
      expect(incomeOnly.summary.totalExpense, 0);
      expect(incomeOnly.summary.netCashFlow, 4500000);
      expect(incomeOnly.summary.averageExpense, isNull);
      expect(incomeOnly.summary.incomeToExpenseRatio, isNull);
      expect(incomeOnly.summary.savingRatePercent, closeTo(100.0, 0.001));
      expect(incomeOnly.summary.savingRatePercent!.isFinite, isTrue);
      expect(incomeOnly.summary.categoryItems, isEmpty);
    });

    test('13. Wallet filtering and getWalletPortfolios reflect actual SQLite balances per wallet', () async {
      await seedTx(
        id: 'w_main_inc',
        title: 'Kas Tunai',
        amount: 1000000,
        type: TransactionType.income,
        categoryId: 'salary',
        walletId: 'main_wallet',
        date: DateTime(2026, 11, 2),
      );
      await seedTx(
        id: 'w_main_exp',
        title: 'Makan Tunai',
        amount: 200000,
        type: TransactionType.expense,
        categoryId: 'food',
        walletId: 'main_wallet',
        date: DateTime(2026, 11, 3),
      );
      await seedTx(
        id: 'w_bca_inc',
        title: 'Transfer BCA',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'business',
        walletId: 'bank_bca',
        date: DateTime(2026, 11, 4),
      );
      await seedTx(
        id: 'w_ewallet_exp',
        title: 'Topup & Belanja OVO',
        amount: 150000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        walletId: 'ewallet',
        date: DateTime(2026, 11, 5),
      );

      final allNov = repository.getMonthlyReport(2026, 11, walletId: 'all');
      expect(allNov.summary.totalIncome, 6000000);
      expect(allNov.summary.totalExpense, 350000);

      final bcaNov = repository.getMonthlyReport(2026, 11, walletId: 'bank_bca');
      expect(bcaNov.summary.totalIncome, 5000000);
      expect(bcaNov.summary.totalExpense, 0);
      expect(bcaNov.summary.categoryItems, isEmpty);

      final ewalletNov = repository.getMonthlyReport(2026, 11, walletId: 'ewallet');
      expect(ewalletNov.summary.totalIncome, 0);
      expect(ewalletNov.summary.totalExpense, 150000);
      expect(ewalletNov.summary.netCashFlow, -150000);
      expect(ewalletNov.summary.categoryItems.single.categoryId, 'shopping');

      final portfolios = repository.getWalletPortfolios(
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
      );
      expect(portfolios.totalBalance, 5650000);
      expect(portfolios.wallets.length, 3);
      expect(
        portfolios.wallets.firstWhere((w) => w.wallet.id == 'main_wallet').currentBalance,
        800000,
      );
      expect(
        portfolios.wallets.firstWhere((w) => w.wallet.id == 'bank_bca').currentBalance,
        5000000,
      );
      expect(
        portfolios.wallets.firstWhere((w) => w.wallet.id == 'ewallet').currentBalance,
        -150000,
      );
    });

    test('14 & 15. Previous period comparison and Feb 29 leap-year handling', () async {
      // Feb 29, 2024 at 23:59:59 vs Feb 28, 2024 vs Mar 1, 2024
      await seedTx(
        id: 'leap_feb28',
        title: 'Makan Feb 28',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2024, 2, 28, 12, 0),
      );
      await seedTx(
        id: 'leap_feb29',
        title: 'Tagihan Kabisat Feb 29',
        amount: 300000,
        type: TransactionType.expense,
        categoryId: 'bills',
        date: DateTime(2024, 2, 29, 23, 59, 59),
      );
      await seedTx(
        id: 'leap_mar1',
        title: 'Makan Maret 1',
        amount: 200000,
        type: TransactionType.expense,
        categoryId: 'food',
        date: DateTime(2024, 3, 1, 0, 0, 0),
      );

      final feb2024 = repository.getMonthlyReport(2024, 2);
      expect(feb2024.summary.dayCount, 29);
      expect(feb2024.summary.totalExpense, 400000);
      expect(feb2024.summary.expenseCount, 2);

      // March 2024 previous period comparison must compare against all of Feb 2024 (400rb)
      final marComparison = repository.getPreviousPeriodComparison(
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 31),
        periodType: ReportPeriod.month,
      );
      expect(marComparison.previousStartDate, DateTime(2024, 2, 1));
      expect(marComparison.previousEndDate, DateTime(2024, 2, 29));
      expect(marComparison.previousSummary.totalExpense, 400000);
      expect(marComparison.currentSummary.totalExpense, 200000);
      expect(marComparison.expenseDelta, -200000);
      expect(marComparison.expenseChangePercent, closeTo(-50.0, 0.001));

      // Custom 1-day range on 2024-02-29 compares against 2024-02-28
      final customLeapComparison = repository.getPreviousPeriodComparison(
        startDate: DateTime(2024, 2, 29),
        endDate: DateTime(2024, 2, 29),
        periodType: ReportPeriod.custom,
      );
      expect(customLeapComparison.previousStartDate, DateTime(2024, 2, 28));
      expect(customLeapComparison.previousEndDate, DateTime(2024, 2, 28));
      expect(customLeapComparison.currentSummary.totalExpense, 300000);
      expect(customLeapComparison.previousSummary.totalExpense, 100000);
      expect(customLeapComparison.expenseDelta, 200000);
      expect(customLeapComparison.expenseChangePercent, closeTo(200.0, 0.001));

      // Leap Q1 2024 ends March 31 and includes Feb 29 + Mar 1
      final q1Leap = repository.getQuarterlyReport(2024, 1);
      expect(q1Leap.summary.totalExpense, 600000);
      expect(q1Leap.monthlyTrend[1].endDate, DateTime(2024, 2, 29));
      expect(q1Leap.monthlyTrend[1].expense, 400000);

      // Non-leap Feb 2025 ends Feb 28
      expect(
        FinanceRepository.getMonthDateRange(2025, 2),
        (start: DateTime(2025, 2, 1), end: DateTime(2025, 2, 28)),
      );
    });
  });
}
