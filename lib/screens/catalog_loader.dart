import 'package:flutter/material.dart';

import '../data/album_repository.dart';
import '../models/album.dart';
import '../state/selection.dart';
import 'catalog_screen.dart';

/// Carga los discos y es dueño de [Selection]. Vive por encima del layout
/// adaptativo, así que el estado sobrevive al cambio entre carrusel y dos
/// paneles.
class CatalogLoader extends StatefulWidget {
  const CatalogLoader({super.key, this.repository = const AlbumRepository()});

  final AlbumRepository repository;

  @override
  State<CatalogLoader> createState() => _CatalogLoaderState();
}

class _CatalogLoaderState extends State<CatalogLoader> {
  late final Future<List<Album>> _albums = widget.repository.loadAll();
  final Selection _selection = Selection();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: _albums,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
            ),
          );
        }
        final albums = snapshot.data;
        if (albums == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CatalogScreen(albums: albums, selection: _selection);
      },
    );
  }
}
