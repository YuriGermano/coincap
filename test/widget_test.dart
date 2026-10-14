import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coincap/main.dart';

void main() {
  testWidgets('CoinCap app smoke test inicia na tela de Login', (WidgetTester tester) async {
    await tester.pumpWidget(const CoinCapApp());
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('TelaInicial exibe navegação e tela de Mercado', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TelaInicial(),
      ),
    );
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
  });
}
