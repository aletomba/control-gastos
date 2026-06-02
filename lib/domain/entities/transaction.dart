enum TransactionSource {
  santanderCredito,
  santanderDebito,
  mercadoPago,
  manual,
}

class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.source,
    this.categoryId,
    this.cardLast4,
    this.gmailMessageId,
    this.isManual = false,
  });

  final int id;
  final double amount;
  final String merchant;
  final DateTime date;
  final TransactionSource source;
  final int? categoryId;
  final String? cardLast4;
  final String? gmailMessageId;
  final bool isManual;

  Transaction copyWith({
    int? id,
    double? amount,
    String? merchant,
    DateTime? date,
    TransactionSource? source,
    int? categoryId,
    String? cardLast4,
    String? gmailMessageId,
    bool? isManual,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      source: source ?? this.source,
      categoryId: categoryId ?? this.categoryId,
      cardLast4: cardLast4 ?? this.cardLast4,
      gmailMessageId: gmailMessageId ?? this.gmailMessageId,
      isManual: isManual ?? this.isManual,
    );
  }
}
