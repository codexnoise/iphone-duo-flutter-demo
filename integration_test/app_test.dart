import 'package:duo_adaptive_demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Flujo explorado antes con el MCP (`flutter_driver_command` sobre
// lib/main_test.dart): favorites-count "0" → tap favorite-toggle → "1".
//
// Limitación: el test no puede cambiar la pose del Duo (no hay API de simctl ni
// de XCTest para la bisagra). Corre en la pose en la que esté el simulador; el
// botón de favorito existe tanto en el carrusel como en el panel del disco.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Catálogo de CDs', () {
    testWidgets('marcar el disco actual como favorito sube el contador', (
      tester,
    ) async {
      await tester.pumpWidget(const DuoAdaptiveApp());
      // Los discos se cargan de assets de forma asíncrona.
      await tester.pumpAndSettle();

      final count = find.byKey(const Key('favorites-count'));
      expect(count, findsOneWidget);
      expect(tester.widget<Text>(count).data, '0');

      await tester.tap(find.byKey(const Key('favorite-toggle')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(count).data, '1');
    });
  });
}
