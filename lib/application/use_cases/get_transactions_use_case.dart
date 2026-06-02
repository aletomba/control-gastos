import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_transaction_repository.dart';

class GetTransactionsUseCase {
  GetTransactionsUseCase(this._repository);

  final ITransactionRepository _repository;

  Future<List<Transaction>> byMonth(int year, int month) =>
      _repository.getByMonth(year, month);

  Future<List<Transaction>> byCategory(int categoryId) =>
      _repository.getByCategory(categoryId);

  Future<List<Transaction>> byDateRange(DateTime from, DateTime to) =>
      _repository.getByDateRange(from, to);

  Future<double> totalByMonth(int year, int month) =>
      _repository.getTotalByMonth(year, month);

  Future<Map<int, double>> totalPerCategoryByMonth(int year, int month) =>
      _repository.getTotalPerCategoryByMonth(year, month);
}
