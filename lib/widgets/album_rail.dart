import 'package:flutter/material.dart';

import '../models/album.dart';
import '../theme/app_theme.dart';
import 'generated_cover.dart';

/// Riel vertical con una miniatura circular por disco y el rótulo "ARCHIVAL".
class AlbumRail extends StatelessWidget {
  const AlbumRail({
    super.key,
    required this.albums,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double width = 72;

  final List<Album> albums;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Vault.surface1,
        border: Border(right: BorderSide(color: Vault.hairline)),
      ),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  for (var i = 0; i < albums.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: GestureDetector(
                          key: Key('rail-$i'),
                          onTap: () => onSelected(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i == selectedIndex
                                    ? Vault.mint
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: GeneratedCover(album: albums[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  'ARCHIVAL',
                  style: ledgerLabel(fontSize: 10, color: Vault.granite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
