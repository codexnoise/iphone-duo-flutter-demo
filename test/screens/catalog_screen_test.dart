import 'package:duo_adaptive_demo/models/album.dart';
import 'package:duo_adaptive_demo/screens/catalog_screen.dart';
import 'package:duo_adaptive_demo/state/selection.dart';
import 'package:duo_adaptive_demo/widgets/album_detail_pane.dart';
import 'package:duo_adaptive_demo/widgets/album_hero_pane.dart';
import 'package:duo_adaptive_demo/widgets/album_rail.dart';
import 'package:duo_adaptive_demo/widgets/cover_carousel.dart';
import 'package:duo_adaptive_demo/widgets/album_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _albums = [
  Album(
    id: 4214311,
    title: 'Gorillaz',
    artist: 'Gorillaz',
    year: 2001,
    tracks: [Track(position: '1', title: 'Re-Hash', duration: '3:40')],
  ),
  Album(
    id: 9100081,
    title: 'Disko 0',
    artist: 'Sal Y Mileto',
    year: 2001,
    tracks: [Track(position: '1', title: 'Avisos Klasificados')],
  ),
];

/// Construye el catálogo en una ventana de [size] pt (devicePixelRatio 1).
Future<Selection> _pumpCatalog(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final selection = Selection();
  addTearDown(selection.dispose);
  await tester.pumpWidget(
    MaterialApp(home: CatalogScreen(albums: _albums, selection: selection)),
  );
  return selection;
}

void main() {
  group('CatalogScreen', () {
    testWidgets('a 466 pt de ancho (Duo cerrado) muestra el carrusel', (
      tester,
    ) async {
      await _pumpCatalog(tester, const Size(466, 900));

      expect(find.byType(CoverCarousel), findsOneWidget);
      expect(find.byType(AlbumRail), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 890 pt de ancho muestra los dos paneles sin overflow', (
      tester,
    ) async {
      await _pumpCatalog(tester, const Size(890, 669));

      expect(find.byType(CoverCarousel), findsNothing);
      expect(find.byType(AlbumRail), findsOneWidget);
      expect(find.byType(AlbumHeroPane), findsOneWidget);
      expect(find.byType(AlbumDetailPane), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 669 pt de ancho (interna en vertical) no hay overflow', (
      tester,
    ) async {
      await _pumpCatalog(tester, const Size(669, 951));

      expect(find.byType(AlbumRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el botón de favorito sube el contador', (tester) async {
      await _pumpCatalog(tester, const Size(466, 900));
      final count = find.byKey(const Key('favorites-count'));
      expect(tester.widget<Text>(count).data, '0');

      await tester.tap(find.byKey(const Key('favorite-toggle')));
      await tester.pump();

      expect(tester.widget<Text>(count).data, '1');
    });

    testWidgets('el disco seleccionado se conserva al pasar a dos paneles', (
      tester,
    ) async {
      final selection = await _pumpCatalog(tester, const Size(466, 900));
      selection.select(1);
      await tester.pump();

      tester.view.physicalSize = const Size(890, 669);
      await tester.pump();

      expect(selection.index, 1);
      expect(
        find.descendant(
          of: find.byType(AlbumHeroPane),
          matching: find.text('Disko 0'),
        ),
        findsOneWidget,
      );
    });
  });

  group('AlbumHeroPane', () {
    Future<void> pumpHero(WidgetTester tester, Size size) {
      return tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.fromSize(
              size: size,
              child: AlbumHeroPane(
                album: _albums.first,
                isFavorite: false,
                onToggleFavorite: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('en un espacio ancho y bajo pone la portada a la izquierda', (
      tester,
    ) async {
      // La mitad de arriba del Duo en modo mesa, sin el riel.
      await pumpHero(tester, const Size(597, 302));

      final cover = tester.getRect(find.byType(AlbumCover));
      final title = tester.getRect(find.text('Gorillaz').last);
      expect(cover.right, lessThan(title.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('en un espacio alto pone la portada arriba', (tester) async {
      await pumpHero(tester, const Size(262, 797));

      final cover = tester.getRect(find.byType(AlbumCover));
      final title = tester.getRect(find.text('Gorillaz').last);
      expect(cover.bottom, lessThanOrEqualTo(title.top));
      expect(tester.takeException(), isNull);
    });
  });
}
