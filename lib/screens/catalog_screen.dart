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
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            titleSpacing: 20,
            title: const VaultTitle(),
            actions: [FavoritesBadge(count: selection.favoritesCount)],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final posture = _postureOf(DuoMediaQuery.statusOf(context));
              final fold = _verticalFold(DuoMediaQuery.regionsOf(context));
              final layout = layoutFor(
                width: constraints.maxWidth,
                posture: posture,
                foldLeft: fold?.left,
                foldRight: fold?.right,
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
                    child: PoseBadge(
                      posture: posture,
                      width: constraints.maxWidth,
                      layout: layout,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Dos paneles separados donde indique [layout]: por la mitad o, con el Duo
  /// plegado a medias, exactamente en el pliegue.
  Widget _buildLargeScreenLayout(CatalogLayout layout) {
    final album = albums[selection.index];
    return Row(
      children: [
        SizedBox(
          width: layout.leftPaneWidth,
          child: Row(
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
          ),
        ),
        if (layout.gapWidth > 0)
          SizedBox(width: layout.gapWidth)
        else
          const VerticalDivider(width: 1),
        Expanded(child: AlbumDetailPane(album: album)),
      ],
    );
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

/// El pliegue como franja vertical, o null si no hay región de división o
/// viene en horizontal.
Rect? _verticalFold(List<ReservedRegion> regions) {
  for (final region in regions) {
    if (region.kind == ReservedRegionKind.division &&
        region.bounds.height > region.bounds.width) {
      return region.bounds;
    }
  }
  return null;
}
