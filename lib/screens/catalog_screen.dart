import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../widgets/cover_carousel.dart';
import '../widgets/favorites_badge.dart';
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
          body: CoverCarousel(albums: albums, selection: selection),
        );
      },
    );
  }
}
