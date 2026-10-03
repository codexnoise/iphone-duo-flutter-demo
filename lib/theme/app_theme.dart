import 'package:flutter/material.dart';

/// Serif de alto contraste que viene con iOS.
const String kDisplayFontFamily = 'Didot';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFFE4572E),
    scaffoldBackgroundColor: const Color(0xFF1C1A19),
  );
}

/// Estilo de los títulos de disco.
TextStyle displayTitleStyle(double fontSize) {
  return TextStyle(
    fontFamily: kDisplayFontFamily,
    fontFamilyFallback: const ['Georgia'],
    fontSize: fontSize,
    height: 1.0,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
