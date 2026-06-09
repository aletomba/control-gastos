import 'package:html/parser.dart' as html_parser;

import '../../domain/entities/transaction.dart';
import '../services/gmail_service.dart';

/// Parsea emails de notificación de Mercado Pago Argentina.
class MercadoPagoParser {
  /// Retorna null si el email no es una notificación de pago/compra de Mercado Pago.
  static Transaction? parse(RawEmail email) {
    final body = email.body;

    if (!_isExpenseEmail(body)) return null;

    final amount = _extractAmount(body);
    final merchant = _extractMerchant(body, email.subject);

    if (amount == null) return null;

    return Transaction(
      id: 0,
      amount: amount,
      merchant: merchant ?? 'Mercado Pago',
      date: email.date,
      source: TransactionSource.mercadoPago,
      gmailMessageId: email.id,
      isManual: false,
    );
  }

  static bool _isExpenseEmail(String body) {
    final lower = body.toLowerCase();
    return lower.contains('pagaste') ||
        lower.contains('realizaste un pago') ||
        lower.contains('tu pago fue aprobado') ||
        lower.contains('compraste') ||
        lower.contains('transferiste');
  }

  static double? _extractAmount(String body) {
    final doc = html_parser.parse(body);
    final text = doc.body?.text ?? body;

    final patterns = [
      RegExp(r'\$\s*([\d\.]+,\d{2})'),          // $ 1.234,56
      RegExp(r'ARS\s*([\d\.]+,\d{2})'),          // ARS 1.234,56
      RegExp(r'por\s+\$\s*([\d\.]+,\d{2})', caseSensitive: false),
      RegExp(r'TOTAL[:\s]+\$?\s*([\d\.]+,\d{2})', caseSensitive: false),
      RegExp(r'\$\s*([\d,]+\.\d{2})'),           // formato con punto decimal
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseArgentineAmount(match.group(1)!);
      }
    }
    return null;
  }

  static double? _parseArgentineAmount(String raw) {
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static String? _extractMerchant(String body, String subject) {
    final doc = html_parser.parse(body);
    final text = doc.body?.text ?? body;

    final patterns = [
      RegExp(r'(?:pagaste a|compraste en|pago a)\s+([^\n$<]{3,60})', caseSensitive: false),
      RegExp(r'COMERCIO[:\s]+([^\n<]{3,60})', caseSensitive: false),
      RegExp(r'DESTINATARIO[:\s]+([^\n<]{3,60})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim().toUpperCase();
      }
    }

    // Fallback: extraer del subject
    final subjectPattern = RegExp(r'(?:pagaste a|compraste en)\s+([^\s].+)', caseSensitive: false);
    final subjectMatch = subjectPattern.firstMatch(subject);
    if (subjectMatch != null) {
      return subjectMatch.group(1)!.trim().toUpperCase();
    }

    return null;
  }
}
