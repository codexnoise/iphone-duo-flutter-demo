import 'package:flutter/material.dart';

import '../models/album.dart';
import 'generated_cover.dart';

/// Portada de un disco: la real de Discogs si está en `assets/covers/` (solo en
/// builds locales; ver tool/fetch_covers.dart) y, si no, la generada por código.
class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/covers/${album.id}.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          GeneratedCover(album: album),
    );
  }
}
