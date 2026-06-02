abstract interface class ISyncLogRepository {
  Future<DateTime?> getLastSync(String source);
  Future<void> updateLastSync(String source, DateTime date);
}
