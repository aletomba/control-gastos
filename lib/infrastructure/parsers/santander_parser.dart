import 'package:html/parser.dart' as html_parser;

import '../../domain/entities/transaction.dart';
import '../services/gmail_service.dart';

/// Parsea emails de notificación de Santander Argentina.
/// Soporta compras con tarjeta de crédito y débito.
class SantanderParser {
  /// Retorna null si el email no corresponde a una notificación de compra de Santander.
  static Transaction? parse(RawEmail email) {
    final body = email.body;

    // Detectar si es un email de compra
    if (!_isExpenseEmail(body)) return null;

    final amount = _extractAmount(body);
    final merchant = _extractMerchant(body);
    final cardLast4 = _extractCardLast4(body);
    final source = _extractSource(body);

    if (amount == null || merchant == null) return null;

    return Transaction(
      id: 0, // asignado por la BD
      amount: amount,
      merchant: merchant,
      date: email.date,
      source: source,
      cardLast4: cardLast4,
      gmailMessageId: email.id,
      isManual: false,
    );
  }

  static bool _isExpenseEmail(String body) {
    final lower = body.toLowerCase();
    return lower.contains('compra aprobada') ||
        lower.contains('consumo aprobado') ||
        lower.contains('realizaste una compra');
  }

  static double? _extractAmount(String body) {
    // Patrón: $ 1.234,56 o $1234.56 o ARS 1.234,56
    final patterns = [
      RegExp(r'\$\s*([\d\.]+,\d{2})'),       // $ 1.234,56
      RegExp(r'ARS\s*([\d\.]+,\d{2})'),       // ARS 1.234,56
      RegExp(r'\$\s*([\d,]+\.\d{2})'),        // $ 1,234.56
      RegExp(r'IMPORTE[:\s]+\$?\s*([\d\.]+,\d{2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(1)!;
        return _parseArgentineAmount(raw);
      }
    }
    return null;
  }

  static double _parseArgentineAmount(String raw) {
    // Formato argentino: 1.234,56 → 1234.56
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  static String? _extractMerchant(String body) {
    // Intentar con HTML parseado primero
    final doc = html_parser.parse(body);
    final text = doc.body?.text ?? body;

    final patterns = [
      RegExp(r'COMERCIO[:\s]+([^\n<]{3,60})', caseSensitive: false),
      RegExp(r'ESTABLECIMIENTO[:\s]+([^\n<]{3,60})', caseSensitive: false),
      // "en NOMBRE" pero solo si contiene al menos una letra (evita "en 1234.")
      RegExp(r'en\s+([A-Z][A-Z0-9 &\.\-\/]{2,49})\s*(?:\n|<|\.|por)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim().toUpperCase();
      }
    }
    return null;
  }

  static String? _extractCardLast4(String body) {
    final pattern = RegExp(r'(?:terminada en|termina en|tarjeta[^0-9]*)\s*(\d{4})', caseSensitive: false);
    final match = pattern.firstMatch(body);
    return match?.group(1);
  }

  static TransactionSource _extractSource(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('débito') || lower.contains('debito')) {
      return TransactionSource.santanderDebito;
    }
    return TransactionSource.santanderCredito;
  }
}
