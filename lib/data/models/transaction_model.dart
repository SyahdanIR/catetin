enum TransactionType {
  income,
  expense,
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final DateTime date;
  final String? notes;
  final bool isRecurring;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.notes,
    this.isRecurring = false,
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    DateTime? date,
    String? notes,
    bool? isRecurring,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
