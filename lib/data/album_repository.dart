import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/album.dart';

/// Releases de Discogs del catálogo, en el orden en que se muestran.
const List<int> kReleaseIds = [4214311, 13115020, 9100081, 11066248, 8172924];

class AlbumLoadException implements Exception {
  const AlbumLoadException(this.releaseId, this.cause);

  final int releaseId;
  final Object cause;

  @override
  String toString() => 'No se pudo cargar el release $releaseId: $cause';
}

class AlbumRepository {
  const AlbumRepository({this.bundle});

  /// Bundle del que se leen los assets; por defecto, [rootBundle].
  final AssetBundle? bundle;

  Future<List<Album>> loadAll() async {
    final source = bundle ?? rootBundle;
    final albums = <Album>[];
    for (final id in kReleaseIds) {
      try {
        final raw = await source.loadString('assets/discogs/$id.json');
        albums.add(Album.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (error) {
        throw AlbumLoadException(id, error);
      }
    }
    return albums;
  }
}
