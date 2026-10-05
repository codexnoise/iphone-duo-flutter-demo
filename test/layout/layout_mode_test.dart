import 'package:duo_adaptive_demo/layout/layout_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layoutFor', () {
    test('ancho angosto con el teléfono cerrado es compacto', () {
      final layout = layoutFor(width: 466, posture: FoldPosture.closed);
      expect(layout.mode, LayoutMode.compact);
    });

    test('el breakpoint exacto sigue siendo compacto', () {
      final layout = layoutFor(
        width: largeScreenMinWidth,
        posture: FoldPosture.fullyOpen,
      );
      expect(layout.mode, LayoutMode.compact);
    });

    test('justo por encima del breakpoint son dos paneles', () {
      final layout = layoutFor(
        width: largeScreenMinWidth + 0.5,
        posture: FoldPosture.fullyOpen,
      );
      expect(layout.mode, LayoutMode.dualPane);
    });

    test('abierto del todo divide al 50 % y sin hueco', () {
      final layout = layoutFor(width: 669, posture: FoldPosture.fullyOpen);
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 334.5));
    });

    test('abierto del todo ignora la región del pliegue', () {
      final layout = layoutFor(
        width: 890,
        posture: FoldPosture.fullyOpen,
        foldLeft: 425,
        foldRight: 465,
      );
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 445));
    });

    test('plegado parcial separa los paneles en el pliegue', () {
      final layout = layoutFor(
        width: 890,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 425,
        foldRight: 465,
      );
      expect(
        layout,
        const CatalogLayout.dualPane(leftPaneWidth: 425, gapWidth: 40),
      );
    });

    test('plegado parcial sin región todavía divide al 50 %', () {
      final layout = layoutFor(width: 890, posture: FoldPosture.partiallyOpen);
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 445));
    });

    test('un pliegue fuera del ancho disponible se ignora', () {
      final layout = layoutFor(
        width: 669,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 660,
        foldRight: 700,
      );
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 334.5));
    });

    test('cerrado pero ancho (externa en horizontal) son dos paneles', () {
      final layout = layoutFor(width: 678, posture: FoldPosture.closed);
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 339));
    });

    test('compacto aunque la postura sea parcial', () {
      final layout = layoutFor(
        width: 466,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 200,
        foldRight: 240,
      );
      expect(layout, const CatalogLayout.compact());
    });
  });
}
