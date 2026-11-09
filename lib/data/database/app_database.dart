import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show Color, IconData;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

part 'app_database.g.dart';

/// Wallets table
class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categories table
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income', 'expense', 'both'
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  IntColumn get bgColorValue => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Transactions table
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  IntColumn get amount => integer()(); // Integer IDR amounts
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get walletId => text().references(Wallets, #id)();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual' or 'receipt'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Wallets, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // 1. Seed default wallet: "Dompet Utama" (AGENTS.md Section 7)
        await into(wallets).insert(
          WalletsCompanion.insert(
            id: 'main_wallet',
            name: 'Dompet Utama',
            initialBalance: const Value(0),
            createdAt: DateTime(2026, 1, 1),
          ),
          mode: InsertMode.insertOrIgnore,
        );

        // 2. Seed default categories (AGENTS.md Phase 1 requirements)
        for (final cat in CategoryModel.defaultCategories) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              id: cat.id,
              name: cat.name,
              type: cat.type.name,
              iconCodePoint: cat.icon.codePoint,
              colorValue: cat.color.toARGB32(),
              bgColorValue: cat.bgColor.toARGB32(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      },
    );
  }

  // --- Transaction Queries ---

  Future<List<TransactionModel>> getAllTransactions() async {
    final rows = await (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)
          ]))
        .get();

    return rows.map((row) => _rowToTransaction(row)).toList();
  }

  Stream<List<TransactionModel>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)
          ]))
        .watch()
        .map((rows) => rows.map((row) => _rowToTransaction(row)).toList());
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final query = select(transactions)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _rowToTransaction(row);
  }

  Future<void> insertTransactionRow(TransactionModel tx) async {
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: tx.id,
        title: tx.title,
        type: tx.type.name,
        amount: tx.amount,
        categoryId: tx.categoryId,
        walletId: tx.walletId,
        transactionDate: tx.transactionDate,
        note: Value(tx.note),
        source: Value(tx.source),
        createdAt: tx.createdAt,
        updatedAt: tx.updatedAt,
        isRecurring: Value(tx.isRecurring),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateTransactionRow(TransactionModel tx) async {
    await (update(transactions)..where((t) => t.id.equals(tx.id))).write(
      TransactionsCompanion(
        title: Value(tx.title),
        type: Value(tx.type.name),
        amount: Value(tx.amount),
        categoryId: Value(tx.categoryId),
        walletId: Value(tx.walletId),
        transactionDate: Value(tx.transactionDate),
        note: Value(tx.note),
        source: Value(tx.source),
        updatedAt: Value(DateTime.now()),
        isRecurring: Value(tx.isRecurring),
      ),
    );
  }

  Future<void> deleteTransactionRow(String id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  // --- Wallet Queries ---

  Future<List<WalletModel>> getAllWallets() async {
    final rows = await select(wallets).get();
    return rows
        .map((row) => WalletModel(
              id: row.id,
              name: row.name,
              initialBalance: row.initialBalance,
              createdAt: row.createdAt,
            ))
        .toList();
  }

  Future<void> insertWalletRow(WalletModel w) async {
    await into(wallets).insert(
      WalletsCompanion.insert(
        id: w.id,
        name: w.name,
        initialBalance: Value(w.initialBalance),
        createdAt: w.createdAt,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  // --- Category Queries ---

  Future<List<CategoryModel>> getAllCategories() async {
    final rows = await select(categories).get();
    return rows.map((row) {
      final categoryType = row.type == 'income'
          ? CategoryType.income
          : (row.type == 'expense' ? CategoryType.expense : CategoryType.both);
      return CategoryModel(
        id: row.id,
        name: row.name,
        // ignore: non_const_argument_for_const_parameter
        icon: IconData(row.iconCodePoint, fontFamily: 'MaterialIcons'),
        color: Color(row.colorValue),
        bgColor: Color(row.bgColorValue),
        type: categoryType,
      );
    }).toList();
  }

  TransactionModel _rowToTransaction(Transaction row) {
    return TransactionModel(
      id: row.id,
      title: row.title,
      amount: row.amount,
      type: row.type == 'income' ? TransactionType.income : TransactionType.expense,
      categoryId: row.categoryId,
      walletId: row.walletId,
      transactionDate: row.transactionDate,
      note: row.note,
      source: row.source,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isRecurring: row.isRecurring,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dompetku.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
