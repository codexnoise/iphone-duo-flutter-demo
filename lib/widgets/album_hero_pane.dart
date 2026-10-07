import 'package:flutter/material.dart';

import '../models/album.dart';
import '../theme/app_theme.dart';
import 'album_title.dart';
import 'archive_chip.dart';
import 'favorite_button.dart';
import 'generated_cover.dart';

/// Proporción ancho / alto a partir de la cual el panel es "ancho y bajo"
/// (p. ej. la mitad de arriba del Duo plegado en modo mesa) y la portada pasa
/// a la izquierda de los datos.
const double wideHeroMinAspectRatio = 1.3;

/// Panel izquierdo del modo de dos paneles: portada en arco con un CD
/// asomando por detrás y los datos del disco, debajo o al lado según el
/// espacio que recibe.
class AlbumHeroPane extends StatelessWidget {
  const AlbumHeroPane({
    super.key,
    required this.album,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Album album;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >
                constraints.maxHeight * wideHeroMinAspectRatio) {
              return _buildWideLayout();
            }
            return _buildTallLayout();
          },
        ),
      ),
    );
  }

  /// Ancho y bajo: portada a la izquierda, datos a la derecha.
  Widget _buildWideLayout() {
    return Row(
      children: [
        _Artwork(album: album),
        const SizedBox(width: 24),
        Expanded(
          child: _Details(
            album: album,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            titleSize: 28,
            titleMaxLines: 2,
          ),
        ),
      ],
    );
  }

  /// Alto o cuadrado: portada arriba, datos abajo.
  Widget _buildTallLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La zona de la portada absorbe todo el alto sobrante: en poses bajas
        // se encoge ella, no el bloque de texto.
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: _Artwork(album: album),
          ),
        ),
        _Details(
          album: album,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          titleSize: 36,
          titleMaxLines: 3,
        ),
      ],
    );
  }
}

/// Portada en arco con el CD asomando por detrás, en una caja cuadrada.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          const Align(
            alignment: Alignment(1, -0.6),
            child: FractionallySizedBox(widthFactor: 0.66, child: _Disc()),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.72,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(999),
                ),
                child: GeneratedCover(album: album),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Artista, título, "año · país · sello", pastillas y botón de favorito.
class _Details extends StatelessWidget {
  const _Details({
    required this.album,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.titleSize,
    required this.titleMaxLines,
  });

  final Album album;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final double titleSize;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (album.year != null) '${album.year}',
      ?album.country,
      ?album.label,
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(album.artist.toUpperCase(), style: ledgerLabel(color: Vault.ochre)),
        const SizedBox(height: 6),
        AlbumTitle(
          title: album.title,
          fontSize: titleSize,
          maxLines: titleMaxLines,
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            details,
            style: const TextStyle(color: Vault.stone, fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: archiveChipsFor(album)),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        FavoriteButton(
          key: const Key('favorite-toggle'),
          isFavorite: isFavorite,
          onPressed: onToggleFavorite,
        ),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFDADADA),
              Color(0xFF8E8E8E),
              Color(0xFFF2F2F2),
              Color(0xFF9A9A9A),
              Color(0xFFDADADA),
            ],
          ),
        ),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.24,
            heightFactor: 0.24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Vault.canvas,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
