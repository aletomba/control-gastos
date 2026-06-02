import 'package:control_gastos/domain/entities/transaction.dart';
import 'package:control_gastos/infrastructure/parsers/mercado_pago_parser.dart';
import 'package:control_gastos/infrastructure/services/gmail_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MercadoPagoParser', () {
    RawEmail makeEmail(String body, {String subject = 'Tu pago fue aprobado'}) {
      return RawEmail(
        id: 'mp-msg-id-001',
        sender: 'no-reply@mail.mercadopago.com',
        subject: subject,
        body: body,
        date: DateTime(2026, 6, 1, 10, 0),
      );
    }

    test('parsea pago a comercio correctamente', () {
      final body = '''
        Tu pago fue aprobado
        Pagaste a RAPPI ARGENTINA
        por \$ 3.200,00
      ''';

      final result = MercadoPagoParser.parse(makeEmail(body));

      expect(result, isNotNull);
      expect(result!.amount, 3200.0);
      expect(result.merchant, contains('RAPPI'));
      expect(result.source, TransactionSource.mercadoPago);
      expect(result.isManual, false);
    });

    test('parsea compra en comercio correctamente', () {
      final body = '''
        Compraste en WALMART ONLINE
        TOTAL: \$ 12.450,99
      ''';

      final result = MercadoPagoParser.parse(makeEmail(body));

      expect(result, isNotNull);
      expect(result!.amount, 12450.99);
      expect(result.merchant, contains('WALMART'));
    });

    test('retorna null si no es email de gasto', () {
      final body = 'Recibiste un depósito de \$ 5.000,00';
      final result = MercadoPagoParser.parse(makeEmail(body));
      expect(result, isNull);
    });

    test('retorna null si no hay monto', () {
      final body = 'Pagaste a COMERCIO ABC sin monto especificado';
      final result = MercadoPagoParser.parse(makeEmail(body));
      expect(result, isNull);
    });

    test('usa merchant del subject como fallback', () {
      final body = 'Pagaste. Importe: \$ 500,00';
      final result = MercadoPagoParser.parse(
        makeEmail(body, subject: 'Compraste en NETFLIX'),
      );
      expect(result?.merchant, contains('NETFLIX'));
    });

    test('usa Mercado Pago como merchant cuando no encuentra comercio', () {
      final body = 'Realizaste un pago por \$ 100,00';
      final result = MercadoPagoParser.parse(makeEmail(body));
      expect(result?.merchant, 'Mercado Pago');
    });

    test('preserva el gmailMessageId para deduplicación', () {
      final body = 'Pagaste a UBER por \$ 800,00';
      final email = RawEmail(
        id: 'unique-mp-id-abc',
        sender: 'no-reply@mail.mercadopago.com',
        subject: 'Tu pago fue aprobado',
        body: body,
        date: DateTime.now(),
      );
      final result = MercadoPagoParser.parse(email);
      expect(result?.gmailMessageId, 'unique-mp-id-abc');
    });
  });
}
