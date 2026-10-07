import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import '../layout/layout_mode.dart';
import '../models/album.dart';
import '../state/selection.dart';
import '../widgets/album_detail_pane.dart';
import '../widgets/album_hero_pane.dart';
import '../widgets/album_rail.dart';
import '../widgets/cover_carousel.dart';
import '../widgets/favorites_badge.dart';
import '../widgets/pose_badge.dart';
import '../widgets/vault_title.dart';

/// Si se muestra la insignia de pose. Por defecto queda fuera de la vista (pero
/// en el árbol, legible por el MCP); se activa con
/// `--dart-define=SHOW_POSE_BADGE=true`.
const bool _showPoseBadge = bool.fromEnvironment('SHOW_POSE_BADGE');

/// Alto del AppBar; el body empieza debajo de él y de la barra de estado.
const double _toolbarHeight = 72;

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    super.key,
    required this.albums,
    required this.selection,
  });

  final List<Album> albums;
  final Selection selection;

  @override
  Widget build(BuildContext context) {
    // Se lee aquí, fuera del Scaffold: dentro del body el Scaffold ya quitó el
    // padding superior porque lo consume el AppBar.
    final insets = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: _toolbarHeight,
            titleSpacing: 20,
            title: const VaultTitle(),
            actions: [FavoritesBadge(count: selection.favoritesCount)],
          ),
          // En horizontal iOS reserva un lateral (cámara y barra de estado:
          // 84 pt en el Duo abierto) que el body debe respetar.
          body: SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final posture = _postureOf(DuoMediaQuery.statusOf(context));
                // La región llega en coordenadas de la ventana; se pasa a las del
                // body, que empieza bajo la barra de estado y el AppBar y después
                // del inset lateral izquierdo.
                final bodyOrigin = Offset(
                  insets.left,
                  insets.top + _toolbarHeight,
                );
                final fold = _division(DuoMediaQuery.regionsOf(context))
                    ?.shift(-bodyOrigin);
                final isVertical = fold != null && fold.height > fold.width;
                final layout = layoutFor(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  posture: posture,
                  foldLeft: isVertical ? fold.left : null,
                  foldRight: isVertical ? fold.right : null,
                  foldTop: fold != null && !isVertical ? fold.top : null,
                  foldBottom: fold != null && !isVertical ? fold.bottom : null,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    switch (layout.mode) {
                      LayoutMode.compact => _buildSmallScreenLayout(),
                      LayoutMode.dualPane => _buildLargeScreenLayout(layout),
                    },
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Offstage(
                        offstage: !_showPoseBadge,
                        child: PoseBadge(
                          posture: posture,
                          width: constraints.maxWidth,
                          layout: layout,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Dos paneles separados donde indique [layout]: por la mitad o, con el Duo
  /// plegado a medias, exactamente en el pliegue (lado a lado o apilados).
  Widget _buildLargeScreenLayout(CatalogLayout layout) {
    final album = albums[selection.index];
    final firstPane = Row(
      children: [
        AlbumRail(
          albums: albums,
          selectedIndex: selection.index,
          onSelected: selection.select,
        ),
        Expanded(
          child: AlbumHeroPane(
            album: album,
            isFavorite: selection.isFavorite(album.id),
            onToggleFavorite: () => selection.toggleFavorite(album.id),
          ),
        ),
      ],
    );
    final detail = Expanded(child: AlbumDetailPane(album: album));
    return switch (layout.axis) {
      PaneAxis.sideBySide => Row(
        children: [
          SizedBox(width: layout.firstPaneExtent, child: firstPane),
          if (layout.gapExtent > 0)
            SizedBox(width: layout.gapExtent)
          else
            const VerticalDivider(width: 1),
          detail,
        ],
      ),
      PaneAxis.stacked => Column(
        children: [
          SizedBox(height: layout.firstPaneExtent, child: firstPane),
          SizedBox(height: layout.gapExtent),
          detail,
        ],
      ),
    };
  }

  Widget _buildSmallScreenLayout() {
    return CoverCarousel(albums: albums, selection: selection);
  }
}

FoldPosture _postureOf(HingeStatus status) => switch (status) {
  HingeStatus.closed => FoldPosture.closed,
  HingeStatus.partiallyOpen => FoldPosture.partiallyOpen,
  HingeStatus.fullyOpen => FoldPosture.fullyOpen,
  HingeStatus.unknown => FoldPosture.unknown,
};

/// La región de división (el pliegue), o null si todavía no llegó.
Rect? _division(List<ReservedRegion> regions) {
  for (final region in regions) {
    if (region.kind == ReservedRegionKind.division) return region.bounds;
  }
  return null;
}
