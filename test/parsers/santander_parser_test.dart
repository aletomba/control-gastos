import 'package:control_gastos/domain/entities/transaction.dart';
import 'package:control_gastos/infrastructure/parsers/santander_parser.dart';
import 'package:control_gastos/infrastructure/services/gmail_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SantanderParser', () {
    RawEmail makeEmail(String body, {String subject = 'Compra aprobada'}) {
      return RawEmail(
        id: 'test-msg-id-001',
        sender: 'notificaciones@servicios.santander.com.ar',
        subject: subject,
        body: body,
        date: DateTime(2026, 6, 1, 14, 30),
      );
    }

    test('parsea compra con crédito correctamente', () {
      final body = '''
        Compra aprobada
        Realizaste una compra con tu tarjeta de crédito terminada en 1234.
        COMERCIO: DISCO SA
        IMPORTE: \$ 2.500,00
      ''';

      final result = SantanderParser.parse(makeEmail(body));

      expect(result, isNotNull);
      expect(result!.amount, 2500.0);
      expect(result.merchant, contains('DISCO'));
      expect(result.cardLast4, '1234');
      expect(result.source, TransactionSource.santanderCredito);
      expect(result.gmailMessageId, 'test-msg-id-001');
      expect(result.isManual, false);
    });

    test('parsea compra con débito correctamente', () {
      final body = '''
        Consumo aprobado
        Realizaste una compra con tu tarjeta de débito terminada en 5678.
        COMERCIO: YPF ESTACION 123
        IMPORTE: \$ 15.800,50
      ''';

      final result = SantanderParser.parse(makeEmail(body));

      expect(result, isNotNull);
      expect(result!.amount, 15800.50);
      expect(result.source, TransactionSource.santanderDebito);
      expect(result.cardLast4, '5678');
    });

    test('retorna null si no es un email de compra', () {
      final body = 'Su resumen de cuenta del mes de Mayo 2026 está disponible.';
      final result = SantanderParser.parse(makeEmail(body));
      expect(result, isNull);
    });

    test('retorna null si no se puede extraer monto', () {
      final body = 'Compra aprobada en COMERCIO SIN MONTO';
      final result = SantanderParser.parse(makeEmail(body));
      expect(result, isNull);
    });

    test('parsea montos con formato de miles correctamente', () {
      final body = '''
        Compra aprobada
        COMERCIO: NETFLIX
        IMPORTE: \$ 1.234.567,89
      ''';

      final result = SantanderParser.parse(makeEmail(body));
      expect(result?.amount, 1234567.89);
    });

    test('preserva el gmailMessageId para deduplicación', () {
      final body = '''
        Compra aprobada
        COMERCIO: STARBUCKS
        IMPORTE: \$ 850,00
      ''';
      final email = RawEmail(
        id: 'unique-gmail-id-xyz',
        sender: 'notificaciones@servicios.santander.com.ar',
        subject: 'Compra aprobada',
        body: body,
        date: DateTime.now(),
      );

      final result = SantanderParser.parse(email);
      expect(result?.gmailMessageId, 'unique-gmail-id-xyz');
    });
  });
}
