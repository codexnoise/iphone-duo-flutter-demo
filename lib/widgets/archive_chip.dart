import 'package:flutter/material.dart';

import '../models/album.dart';
import '../theme/app_theme.dart';

/// Pastilla con borde fino para datos de catálogo.
class ArchiveChip extends StatelessWidget {
  const ArchiveChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Vault.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label.toUpperCase(),
          style: ledgerLabel(fontSize: 11, color: Vault.alabaster),
        ),
      ),
    );
  }
}

/// Pastillas de formato y número de catálogo de un disco.
List<Widget> archiveChipsFor(Album album) {
  return [
    if (album.formats.isNotEmpty)
      ArchiveChip(
        album.formats.first
            .replaceAll(' (', ' · ')
            .replaceAll(', ', ' · ')
            .replaceAll(')', ''),
      ),
    if (album.catalogNumber case final catalog?) ArchiveChip('Cat. $catalog'),
  ];
}
