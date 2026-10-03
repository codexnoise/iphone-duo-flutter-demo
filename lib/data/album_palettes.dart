import 'package:flutter/material.dart';

/// Colores de la portada generada de un disco. Son propios de la app: no
/// imitan la portada original.
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
    background: Color(0xFF2B1B4A),
    primary: Color(0xFFE94F8A),
    accent: Color(0xFFF6C445),
  ),
  // Daft Punk — Random Access Memories
  13115020: AlbumPalette(
    background: Color(0xFF0E3B43),
    primary: Color(0xFF2EC4B6),
    accent: Color(0xFFFFD166),
  ),
  // Sal y Mileto — Disko 0
  9100081: AlbumPalette(
    background: Color(0xFF3A1010),
    primary: Color(0xFFE4572E),
    accent: Color(0xFFF3A712),
  ),
  // Gondwana — Alabanza
  11066248: AlbumPalette(
    background: Color(0xFF123524),
    primary: Color(0xFF3E8E41),
    accent: Color(0xFFF2C14E),
  ),
  // Cultura Profética — La Dulzura
  8172924: AlbumPalette(
    background: Color(0xFF40204A),
    primary: Color(0xFFF28482),
    accent: Color(0xFFF6BD60),
  ),
};

const AlbumPalette kFallbackPalette = AlbumPalette(
  background: Color(0xFF24211F),
  primary: Color(0xFF8D99AE),
  accent: Color(0xFFEDF2F4),
);

AlbumPalette paletteFor(int releaseId) =>
    kAlbumPalettes[releaseId] ?? kFallbackPalette;
