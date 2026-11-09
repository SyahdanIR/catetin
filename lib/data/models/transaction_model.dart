enum TransactionType {
  income,
  expense,
}

class TransactionModel {
  final String id;
  final String title;
  final int amount; // Monetary amounts in IDR are strictly integers
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final DateTime transactionDate;
  final String? note;
  final String source; // 'manual' or 'receipt'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRecurring;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.transactionDate,
    this.note,
    this.source = 'manual',
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
  });

  // Backward compatibility getters for UI
  DateTime get date => transactionDate;
  String? get notes => note;

  TransactionModel copyWith({
    String? id,
    String? title,
    int? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    DateTime? transactionDate,
    String? note,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
