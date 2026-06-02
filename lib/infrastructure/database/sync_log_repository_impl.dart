import '../../domain/repositories/i_sync_log_repository.dart';
import 'app_database.dart';
import 'package:drift/drift.dart';

class SyncLogRepositoryImpl implements ISyncLogRepository {
  SyncLogRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<DateTime?> getLastSync(String source) async {
    final row = await (_db.select(_db.syncLog)
          ..where((s) => s.source.equals(source)))
        .getSingleOrNull();
    return row?.lastSync;
  }

  @override
  Future<void> updateLastSync(String source, DateTime date) async {
    await _db.into(_db.syncLog).insertOnConflictUpdate(
          SyncLogCompanion(
            source: Value(source),
            lastSync: Value(date),
          ),
        );
  }
}
