import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:control_gastos/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Login screen shows connect button', (WidgetTester tester) async {
    await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(      // ← agregar
        home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Control Gastos'), findsOneWidget);
    expect(find.text('Conectar con Gmail'), findsOneWidget);
  });
}