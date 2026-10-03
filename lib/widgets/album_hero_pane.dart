import 'package:flutter/material.dart';

import '../models/album.dart';
import '../theme/app_theme.dart';
import 'album_title.dart';
import 'archive_chip.dart';
import 'favorite_button.dart';
import 'generated_cover.dart';

/// Panel izquierdo del modo de dos paneles: portada en arco con un CD
/// asomando por detrás y, abajo, los datos del disco.
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
    final details = [
      if (album.year != null) '${album.year}',
      ?album.country,
      ?album.label,
    ].join(' · ');
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Align(
                alignment: Alignment.topLeft,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment(1, -0.6),
                        child: FractionallySizedBox(
                          widthFactor: 0.66,
                          child: _Disc(),
                        ),
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
                ),
              ),
            ),
            const Spacer(),
            Text(
              album.artist.toUpperCase(),
              style: ledgerLabel(color: Vault.ochre),
            ),
            const SizedBox(height: 6),
            AlbumTitle(title: album.title, fontSize: 36),
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
        ),
      ),
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
