import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../widgets/album_detail_pane.dart';
import '../widgets/album_hero_pane.dart';
import '../widgets/album_rail.dart';
import '../widgets/cover_carousel.dart';
import '../widgets/favorites_badge.dart';
import '../widgets/vault_title.dart';

/// Ancho disponible a partir del cual el catálogo pasa a dos paneles.
const double largeScreenMinWidth = 600.0;

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
              if (constraints.maxWidth > largeScreenMinWidth) {
                return _buildLargeScreenLayout();
              }
              return _buildSmallScreenLayout();
            },
          ),
        );
      },
    );
  }

  Widget _buildLargeScreenLayout() {
    final album = albums[selection.index];
    return Row(
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
        const VerticalDivider(width: 1),
        Expanded(child: AlbumDetailPane(album: album)),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return CoverCarousel(albums: albums, selection: selection);
  }
}
