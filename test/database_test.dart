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
}
