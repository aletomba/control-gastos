import 'package:drift/drift.dart';

import '../../domain/entities/transaction.dart' as domain;
import '../../domain/repositories/i_transaction_repository.dart';
import 'app_database.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  TransactionRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<domain.Transaction>> getByMonth(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(from) & t.date.isSmallerThanValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map<domain.Transaction>(AppDatabase.toDomainTransaction).toList();
  }

  @override
  Future<List<domain.Transaction>> getByCategory(int categoryId) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map<domain.Transaction>(AppDatabase.toDomainTransaction).toList();
  }

  @override
  Future<List<domain.Transaction>> getByDateRange(
      DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(from) &
              t.date.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map<domain.Transaction>(AppDatabase.toDomainTransaction).toList();
  }

  @override
  Future<domain.Transaction> insert(domain.Transaction transaction) async {
    final id = await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            amount: transaction.amount,
            merchant: transaction.merchant,
            date: transaction.date,
            source: transaction.source.name,
            categoryId: Value(transaction.categoryId),
            cardLast4: Value(transaction.cardLast4),
            isManual: Value(transaction.isManual),
            gmailMessageId: Value(transaction.gmailMessageId),
          ),
        );
    return transaction.copyWith(id: id);
  }

  @override
  Future<void> update(domain.Transaction transaction) async {
    await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(transaction.id)))
        .write(TransactionsCompanion(
      amount: Value(transaction.amount),
      merchant: Value(transaction.merchant),
      date: Value(transaction.date),
      source: Value(transaction.source.name),
      categoryId: Value(transaction.categoryId),
      cardLast4: Value(transaction.cardLast4),
      isManual: Value(transaction.isManual),
    ));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<bool> existsByGmailMessageId(String gmailMessageId) async {
    final row = await (_db.select(_db.transactions)
          ..where((t) => t.gmailMessageId.equals(gmailMessageId)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<double> getTotalByMonth(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.amount.sum()])
      ..where(_db.transactions.date.isBiggerOrEqualValue(from) &
          _db.transactions.date.isSmallerThanValue(to));
    final result = await query.getSingle();
    return result.read(_db.transactions.amount.sum()) ?? 0.0;
  }

  @override
  Future<Map<int, double>> getTotalPerCategoryByMonth(
      int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.categoryId, _db.transactions.amount.sum()])
      ..where(_db.transactions.date.isBiggerOrEqualValue(from) &
          _db.transactions.date.isSmallerThanValue(to))
      ..groupBy([_db.transactions.categoryId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(_db.transactions.categoryId) != null)
          row.read(_db.transactions.categoryId)!:
              row.read(_db.transactions.amount.sum()) ?? 0.0,
    };
  }
}
