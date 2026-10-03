import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../theme/app_theme.dart';
import 'album_detail_pane.dart';
import 'album_title.dart';
import 'archive_chip.dart';
import 'favorite_button.dart';
import 'generated_cover.dart';

/// Modo compacto: una portada enmarcada por disco, con los controles fijos
/// debajo del carrusel.
class CoverCarousel extends StatefulWidget {
  const CoverCarousel({
    super.key,
    required this.albums,
    required this.selection,
  });

  final List<Album> albums;
  final Selection selection;

  @override
  State<CoverCarousel> createState() => _CoverCarouselState();
}

class _CoverCarouselState extends State<CoverCarousel> {
  // Arranca en el disco seleccionado: al volver de dos paneles se conserva.
  late final PageController _controller = PageController(
    initialPage: widget.selection.index,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails() {
    final album = widget.albums[widget.selection.index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            _SheetHeader(album: album),
            Expanded(child: AlbumDetailPane(album: album)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.albums[widget.selection.index];
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.albums.length,
            onPageChanged: widget.selection.select,
            itemBuilder: (context, index) {
              return _CoverPage(album: widget.albums[index]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PageDots(
                  count: widget.albums.length,
                  index: widget.selection.index,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FavoriteButton(
                      key: const Key('favorite-toggle'),
                      isFavorite: widget.selection.isFavorite(album.id),
                      onPressed: () =>
                          widget.selection.toggleFavorite(album.id),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('open-details'),
                        onPressed: _openDetails,
                        style: FilledButton.styleFrom(
                          backgroundColor: Vault.surface2,
                          foregroundColor: Vault.alabaster,
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Vault.mint,
                        ),
                        label: Text(
                          'VER FICHA Y TRACKS',
                          style: ledgerLabel(color: Vault.alabaster),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (album.year != null) '${album.year}',
      ?album.country,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.85,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Vault.hairline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: GeneratedCover(album: album),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            album.artist.toUpperCase(),
            textAlign: TextAlign.center,
            style: ledgerLabel(color: Vault.ochre),
          ),
          const SizedBox(height: 6),
          AlbumTitle(
            title: album.title,
            fontSize: 34,
            textAlign: TextAlign.center,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: const TextStyle(color: Vault.stone, fontSize: 15),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: archiveChipsFor(album),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: GeneratedCover(album: album),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.artist.toUpperCase(),
                  style: ledgerLabel(fontSize: 10, color: Vault.ochre),
                ),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: serifTitle(20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? Vault.mint : Vault.granite,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
