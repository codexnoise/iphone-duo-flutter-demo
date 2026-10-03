import 'package:flutter/material.dart';

/// Colores de la portada generada de un disco, tomados de la paleta
/// "Archival Modernist". No imitan la portada original.
class AlbumPalette {
  const AlbumPalette({
    required this.background,
    required this.primary,
    required this.accent,
  });

  final Color background;
  final Color primary;
  final Color accent;
}

const Map<int, AlbumPalette> kAlbumPalettes = {
  // Gorillaz — Gorillaz
  4214311: AlbumPalette(
    background: Color(0xFF1F2B22),
    primary: Color(0xFF8AB17D),
    accent: Color(0xFFE76F51),
  ),
  // Daft Punk — Random Access Memories (la de la referencia de Stitch)
  13115020: AlbumPalette(
    background: Color(0xFF0E3B43),
    primary: Color(0xFF2EC4B6),
    accent: Color(0xFFFFD166),
  ),
  // Sal y Mileto — Disko 0
  9100081: AlbumPalette(
    background: Color(0xFF3A1F18),
    primary: Color(0xFFE76F51),
    accent: Color(0xFFFFD166),
  ),
  // Gondwana — Alabanza
  11066248: AlbumPalette(
    background: Color(0xFF14261F),
    primary: Color(0xFF2EC4B6),
    accent: Color(0xFFE76F51),
  ),
  // Cultura Profética — La Dulzura
  8172924: AlbumPalette(
    background: Color(0xFF2B2140),
    primary: Color(0xFFFFD166),
    accent: Color(0xFF2EC4B6),
  ),
};

const AlbumPalette kFallbackPalette = AlbumPalette(
  background: Color(0xFF252220),
  primary: Color(0xFFA8A29E),
  accent: Color(0xFFF4F1EA),
);

AlbumPalette paletteFor(int releaseId) =>
    kAlbumPalettes[releaseId] ?? kFallbackPalette;
