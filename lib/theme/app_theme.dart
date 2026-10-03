import 'package:flutter/material.dart';

/// Tokens del sistema "Archival Modernist" (docs/design/stitch/DESIGN.md).
abstract final class Vault {
  static const canvas = Color(0xFF1C1A19);
  static const surface1 = Color(0xFF252220);
  static const surface2 = Color(0xFF2E2A28);
  static const hairline = Color(0xFF3A3533);
  static const mint = Color(0xFF2EC4B6);
  static const ochre = Color(0xFFFFD166);
  static const vermilion = Color(0xFFE76F51);
  static const deepTeal = Color(0xFF0E3B43);
  static const sage = Color(0xFF8AB17D);
  static const alabaster = Color(0xFFF4F1EA);
  static const stone = Color(0xFFA8A29E);
  static const granite = Color(0xFF6E6763);
}

const String kSerifFamily = 'Bodoni Moda';
const String kSansFamily = 'Plus Jakarta Sans';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: kSansFamily,
    scaffoldBackgroundColor: Vault.canvas,
    dividerColor: Vault.hairline,
    colorScheme: const ColorScheme.dark(
      surface: Vault.canvas,
      surfaceContainerLow: Vault.surface1,
      surfaceContainerHighest: Vault.surface2,
      primary: Vault.mint,
      onPrimary: Vault.canvas,
      secondary: Vault.ochre,
      tertiary: Vault.vermilion,
      onSurface: Vault.alabaster,
      onSurfaceVariant: Vault.stone,
      outline: Vault.hairline,
      outlineVariant: Vault.hairline,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Vault.canvas,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: Vault.hairline)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Vault.surface2,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Vault.alabaster,
      displayColor: Vault.alabaster,
    ),
  );
}

/// Título de disco en Bodoni Moda. Las fuentes son variables: el grosor se
/// fija con [FontVariation].
TextStyle serifTitle(
  double fontSize, {
  bool italic = false,
  Color color = Vault.alabaster,
}) {
  return TextStyle(
    fontFamily: kSerifFamily,
    fontSize: fontSize,
    height: 1.1,
    letterSpacing: -0.01 * fontSize,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: FontWeight.w400,
    fontVariations: const [FontVariation('wght', 400)],
    color: color,
  );
}

/// Etiqueta de registro: se escribe en mayúsculas y lleva tracking amplio.
TextStyle ledgerLabel({double fontSize = 12, Color color = Vault.stone}) {
  return TextStyle(
    fontFamily: kSansFamily,
    fontSize: fontSize,
    height: 1.35,
    letterSpacing: fontSize * 0.1,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation('wght', 600)],
    color: color,
  );
}
