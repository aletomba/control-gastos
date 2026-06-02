import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_transaction_repository.dart';

class SaveManualTransactionUseCase {
  SaveManualTransactionUseCase(this._repository);

  final ITransactionRepository _repository;

  Future<Transaction> execute({
    required double amount,
    required String merchant,
    required DateTime date,
    int? categoryId,
  }) {
    final transaction = Transaction(
      id: 0,
      amount: amount,
      merchant: merchant.toUpperCase().trim(),
      date: date,
      source: TransactionSource.manual,
      categoryId: categoryId,
      isManual: true,
    );
    return _repository.insert(transaction);
  }
}
