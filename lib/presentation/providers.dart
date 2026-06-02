import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/categorize_transaction_use_case.dart';
import '../../application/use_cases/export_csv_use_case.dart';
import '../../application/use_cases/get_transactions_use_case.dart';
import '../../application/use_cases/save_manual_transaction_use_case.dart';
import '../../application/use_cases/sync_emails_use_case.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/category_repository_impl.dart';
import '../../infrastructure/database/sync_log_repository_impl.dart';
import '../../infrastructure/database/transaction_repository_impl.dart';
import '../../infrastructure/services/gmail_service.dart';

// ─── Database ────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── Repositories ────────────────────────────────────────────────────────────

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepositoryImpl(ref.watch(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider((ref) {
  return CategoryRepositoryImpl(ref.watch(appDatabaseProvider));
});

final syncLogRepositoryProvider = Provider((ref) {
  return SyncLogRepositoryImpl(ref.watch(appDatabaseProvider));
});

// ─── Services ────────────────────────────────────────────────────────────────

final gmailServiceProvider = Provider((_) => GmailService());

// ─── Use Cases ───────────────────────────────────────────────────────────────

final categorizeUseCaseProvider = Provider((ref) {
  return CategorizeTransactionUseCase(ref.watch(categoryRepositoryProvider));
});

final syncEmailsUseCaseProvider = Provider((ref) {
  return SyncEmailsUseCase(
    gmailService: ref.watch(gmailServiceProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    syncLogRepository: ref.watch(syncLogRepositoryProvider),
    categorizeUseCase: ref.watch(categorizeUseCaseProvider),
  );
});

final getTransactionsUseCaseProvider = Provider((ref) {
  return GetTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

final saveManualTransactionUseCaseProvider = Provider((ref) {
  return SaveManualTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final exportCsvUseCaseProvider = Provider((ref) {
  return ExportCsvUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

// ─── Estado de autenticación ─────────────────────────────────────────────────

final isSignedInProvider = FutureProvider<bool>((ref) async {
  return ref.watch(gmailServiceProvider).isSignedIn;
});

final userEmailProvider = FutureProvider<String?>((ref) async {
  return ref.watch(gmailServiceProvider).userEmail;
});

// ─── Transacciones del mes actual ────────────────────────────────────────────

final selectedMonthProvider = StateProvider<DateTime>(
  (_) => DateTime(DateTime.now().year, DateTime.now().month),
);

final transactionsByMonthProvider = FutureProvider<List>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(getTransactionsUseCaseProvider)
      .byMonth(month.year, month.month);
});

final monthlyTotalProvider = FutureProvider<double>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(getTransactionsUseCaseProvider)
      .totalByMonth(month.year, month.month);
});

final categoryTotalsProvider = FutureProvider<Map<int, double>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(getTransactionsUseCaseProvider)
      .totalPerCategoryByMonth(month.year, month.month);
});

final categoriesProvider = FutureProvider((ref) async {
  return ref.watch(categoryRepositoryProvider).getAll();
});
