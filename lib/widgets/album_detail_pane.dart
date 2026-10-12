import 'package:flutter/material.dart';

import '../models/album.dart';
import '../theme/app_theme.dart';

/// Ficha de un disco: pestañas segmentadas (Tracks, Créditos, Ficha, Notas)
/// con filas de registro y la atribución de Discogs al pie.
class AlbumDetailPane extends StatelessWidget {
  const AlbumDetailPane({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Vault.surface1,
                border: Border.all(color: Vault.hairline),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Vault.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Vault.canvas,
                  unselectedLabelColor: Vault.stone,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  labelPadding: EdgeInsets.zero,
                  splashBorderRadius: BorderRadius.circular(999),
                  tabs: [
                    Tab(height: 36, text: 'Tracks ${album.tracks.length}'),
                    const Tab(height: 36, text: 'Créditos'),
                    const Tab(height: 36, text: 'Ficha'),
                    const Tab(height: 36, text: 'Notas'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TracksTab(album: album),
                _CreditsTab(album: album),
                _SpecsTab(album: album),
                _NotesTab(album: album),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Vault.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'DATOS DE DISCOGS (CC0)',
                    style: ledgerLabel(fontSize: 10, color: Vault.granite),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const EdgeInsets _tabPadding = EdgeInsets.symmetric(horizontal: 16);

class _TracksTab extends StatelessWidget {
  const _TracksTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _tabPadding,
      itemCount: album.tracks.length,
      itemBuilder: (context, index) {
        final track = album.tracks[index];
        return _LedgerRow(
          leading: track.position,
          title: track.title,
          trailing: track.duration,
        );
      },
    );
  }
}

class _CreditsTab extends StatelessWidget {
  const _CreditsTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    if (album.credits.isEmpty) {
      return const _EmptyTab('Sin créditos en Discogs');
    }
    return ListView.builder(
      padding: _tabPadding,
      itemCount: album.credits.length,
      itemBuilder: (context, index) {
        final credit = album.credits[index];
        return _LedgerRow(title: credit.name, underline: credit.role);
      },
    );
  }
}

class _SpecsTab extends StatelessWidget {
  const _SpecsTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (album.year case final year?) ('Año', '$year'),
      if (album.country case final country?) ('País', country),
      if (album.label case final label?) ('Sello', label),
      if (album.catalogNumber case final catalog?) ('Catálogo', catalog),
      if (album.formats.isNotEmpty) ('Formato', album.formats.join(', ')),
      if (album.genres.isNotEmpty) ('Géneros', album.genres.join(', ')),
      if (album.styles.isNotEmpty) ('Estilos', album.styles.join(', ')),
    ];
    return ListView.builder(
      padding: _tabPadding,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final (label, value) = rows[index];
        return _LedgerRow(overline: label, title: value);
      },
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final notes = album.notes;
    if (notes == null) {
      return const _EmptyTab('Sin notas en Discogs');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        notes,
        style: const TextStyle(color: Vault.stone, fontSize: 14, height: 1.6),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: Vault.stone)),
    );
  }
}

/// Fila de libro de registro: línea fina inferior, posición en granito y
/// duración en piedra.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.title,
    this.leading,
    this.overline,
    this.underline,
    this.trailing,
  });

  final String title;
  final String? leading;
  final String? overline;
  final String? underline;
  final String? trailing;

  static const _figures = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Vault.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (leading case final leading?)
              SizedBox(
                width: 32,
                child: Text(
                  leading,
                  style: const TextStyle(
                    color: Vault.granite,
                    fontSize: 13,
                    fontFeatures: _figures,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overline case final overline?)
                    Text(
                      overline.toUpperCase(),
                      style: ledgerLabel(fontSize: 10),
                    ),
                  Text(title, style: const TextStyle(fontSize: 15)),
                  if (underline case final underline?)
                    Text(
                      underline.toUpperCase(),
                      style: ledgerLabel(fontSize: 10),
                    ),
                ],
              ),
            ),
            if (trailing case final trailing?)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    color: Vault.stone,
                    fontSize: 13,
                    fontFeatures: _figures,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
