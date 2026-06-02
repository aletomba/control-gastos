import 'package:workmanager/workmanager.dart';

import '../../application/use_cases/categorize_transaction_use_case.dart';
import '../../application/use_cases/sync_emails_use_case.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/category_repository_impl.dart';
import '../../infrastructure/database/sync_log_repository_impl.dart';
import '../../infrastructure/database/transaction_repository_impl.dart';
import '../../infrastructure/services/gmail_service.dart';

const _syncTaskName = 'syncExpenseEmails';
const _syncTaskTag = 'expense_sync';

/// Registra el callback del WorkManager. Debe llamarse en main() antes de runApp.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _syncTaskName) return Future.value(true);
    try {
      final db = AppDatabase();
      final txRepo = TransactionRepositoryImpl(db);
      final catRepo = CategoryRepositoryImpl(db);
      final syncLogRepo = SyncLogRepositoryImpl(db);
      final gmailService = GmailService();
      final categorizeUseCase = CategorizeTransactionUseCase(catRepo);

      final useCase = SyncEmailsUseCase(
        gmailService: gmailService,
        transactionRepository: txRepo,
        syncLogRepository: syncLogRepo,
        categorizeUseCase: categorizeUseCase,
      );

      await useCase.execute();
      await db.close();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  /// Registra la tarea periódica (cada 6 horas)
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await _registerPeriodicTask();
  }

  static Future<void> _registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _syncTaskTag,
      _syncTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// Fuerza una sincronización inmediata (ej: desde pull-to-refresh)
  static Future<void> triggerNow() async {
    await Workmanager().registerOneOffTask(
      '${_syncTaskTag}_manual',
      _syncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByTag(_syncTaskTag);
  }
}
