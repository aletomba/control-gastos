import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_sync_log_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../infrastructure/parsers/mercado_pago_parser.dart';
import '../../infrastructure/parsers/santander_parser.dart';
import '../../infrastructure/services/gmail_service.dart';
import 'categorize_transaction_use_case.dart';

class SyncEmailsUseCase {
  SyncEmailsUseCase({
    required this.gmailService,
    required this.transactionRepository,
    required this.syncLogRepository,
    required this.categorizeUseCase,
  });

  final GmailService gmailService;
  final ITransactionRepository transactionRepository;
  final ISyncLogRepository syncLogRepository;
  final CategorizeTransactionUseCase categorizeUseCase;

  /// Retorna el número de transacciones nuevas insertadas
  Future<int> execute() async {
    final lastSync = await syncLogRepository.getLastSync('gmail');
    final since = lastSync != null
        ? lastSync.subtract(const Duration(days: 7))
        : DateTime.now().subtract(const Duration(days: 90));
    final emails = await gmailService.fetchExpenseEmails(since: since);

    int inserted = 0;
    for (final email in emails) {
      // Evitar duplicados
      if (await transactionRepository.existsByGmailMessageId(email.id)) {
        continue;
      }

      Transaction? transaction;

      if (email.sender.contains('santander')) {
        transaction = SantanderParser.parse(email);
      } else if (email.sender.contains('mercadopago')) {
        transaction = MercadoPagoParser.parse(email);
      }

      if (transaction == null) continue;

      // Auto-categorizar
      final categoryId = await categorizeUseCase.execute(transaction.merchant);
      final withCategory = transaction.copyWith(categoryId: categoryId);

      await transactionRepository.insert(withCategory);
      inserted++;
    }

    await syncLogRepository.updateLastSync('gmail', DateTime.now());
    return inserted;
  }
}
