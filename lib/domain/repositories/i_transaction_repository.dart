import '../entities/transaction.dart';

abstract interface class ITransactionRepository {
  Future<List<Transaction>> getByMonth(int year, int month);
  Future<List<Transaction>> getByCategory(int categoryId);
  Future<List<Transaction>> getByDateRange(DateTime from, DateTime to);
  Future<Transaction> insert(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<void> delete(int id);
  Future<bool> existsByGmailMessageId(String gmailMessageId);
  Future<double> getTotalByMonth(int year, int month);
  Future<Map<int, double>> getTotalPerCategoryByMonth(int year, int month);
}
