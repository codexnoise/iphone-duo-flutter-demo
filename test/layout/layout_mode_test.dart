import 'package:duo_adaptive_demo/layout/layout_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layoutFor — ancho', () {
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

    test('cerrado pero ancho (externa en horizontal) son dos paneles', () {
      final layout = layoutFor(width: 678, posture: FoldPosture.closed);
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 339));
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

  group('layoutFor — pliegue vertical (interna en horizontal)', () {
    test('abierto del todo divide al 50 % y sin hueco', () {
      final layout = layoutFor(width: 669, posture: FoldPosture.fullyOpen);
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 334.5));
    });

    test('abierto del todo ignora la región del pliegue', () {
      final layout = layoutFor(
        width: 951,
        posture: FoldPosture.fullyOpen,
        foldLeft: 456,
        foldRight: 496,
      );
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 475.5));
    });

    test('plegado parcial separa los paneles lado a lado en el pliegue', () {
      final layout = layoutFor(
        width: 951,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 456,
        foldRight: 496,
      );
      expect(
        layout,
        const CatalogLayout.sideBySide(firstPaneExtent: 456, gapExtent: 40),
      );
    });

    test('plegado parcial sin región todavía divide al 50 %', () {
      final layout = layoutFor(width: 951, posture: FoldPosture.partiallyOpen);
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 475.5));
    });

    test('un pliegue fuera del ancho disponible se ignora', () {
      final layout = layoutFor(
        width: 669,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 660,
        foldRight: 700,
      );
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 334.5));
    });
  });

  group('layoutFor — pliegue horizontal (interna en vertical)', () {
    test('plegado parcial apila los paneles separados en el pliegue', () {
      final layout = layoutFor(
        width: 669,
        height: 797,
        posture: FoldPosture.partiallyOpen,
        foldTop: 300,
        foldBottom: 340,
      );
      expect(
        layout,
        const CatalogLayout.stacked(firstPaneExtent: 300, gapExtent: 40),
      );
    });

    test('abierto del todo ignora el pliegue horizontal', () {
      final layout = layoutFor(
        width: 669,
        height: 797,
        posture: FoldPosture.fullyOpen,
        foldTop: 300,
        foldBottom: 340,
      );
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 334.5));
    });

    test('un pliegue fuera del alto disponible se ignora', () {
      final layout = layoutFor(
        width: 669,
        height: 797,
        posture: FoldPosture.partiallyOpen,
        foldTop: 790,
        foldBottom: 830,
      );
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 334.5));
    });

    test('sin alto conocido el pliegue horizontal se ignora', () {
      final layout = layoutFor(
        width: 669,
        posture: FoldPosture.partiallyOpen,
        foldTop: 300,
        foldBottom: 340,
      );
      expect(layout, const CatalogLayout.sideBySide(firstPaneExtent: 334.5));
    });
  });
}
