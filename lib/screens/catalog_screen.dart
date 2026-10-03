import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../widgets/favorites_badge.dart';
import '../widgets/generated_cover.dart';

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
            title: const Text('CD Catalog'),
            actions: [FavoritesBadge(count: selection.favoritesCount)],
          ),
          body: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                leading: SizedBox.square(
                  dimension: 56,
                  child: GeneratedCover(album: album),
                ),
                title: Text(album.title),
                subtitle: Text(album.artist),
                selected: index == selection.index,
                onTap: () => selection.select(index),
                trailing: IconButton(
                  icon: Icon(
                    selection.isFavorite(album.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: () => selection.toggleFavorite(album.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
