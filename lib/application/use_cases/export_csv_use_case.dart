import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_category_repository.dart';

class ExportCsvUseCase {
  ExportCsvUseCase(this._transactionRepository, this._categoryRepository);

  final ITransactionRepository _transactionRepository;
  final ICategoryRepository _categoryRepository;

  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_AR');
  final _amountFormat = NumberFormat('#,##0.00', 'es_AR');

  Future<void> execute({required DateTime from, required DateTime to}) async {
    final transactions = await _transactionRepository.getByDateRange(from, to);
    final categories = await _categoryRepository.getAll();
    final categoryMap = {for (final c in categories) c.id: c.name};

    final rows = <List<dynamic>>[
      ['Fecha', 'Comercio', 'Monto', 'Categoría', 'Fuente', 'Tarjeta'],
      ...transactions.map((t) => [
            _dateFormat.format(t.date),
            t.merchant,
            _amountFormat.format(t.amount),
            t.categoryId != null ? categoryMap[t.categoryId] ?? 'Sin categoría' : 'Sin categoría',
            _sourceLabel(t.source),
            t.cardLast4 ?? '-',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode('\uFEFF$csv'); // BOM para Excel

    final dir = await getTemporaryDirectory();
    final fileName =
        'gastos_${DateFormat('yyyy-MM-dd').format(from)}_${DateFormat('yyyy-MM-dd').format(to)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Gastos $fileName',
    );
  }

  String _sourceLabel(TransactionSource source) {
    switch (source) {
      case TransactionSource.santanderCredito:
        return 'Santander Crédito';
      case TransactionSource.santanderDebito:
        return 'Santander Débito';
      case TransactionSource.mercadoPago:
        return 'Mercado Pago';
      case TransactionSource.manual:
        return 'Manual';
    }
  }
}
