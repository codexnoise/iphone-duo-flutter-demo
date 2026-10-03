import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'screens/catalog_screen.dart';

void main() {
  runApp(const DuoAdaptiveApp());
}

class DuoAdaptiveApp extends StatelessWidget {
  const DuoAdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FoldableProvider(
      child: MaterialApp(
        title: 'Products',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const CatalogScreen(),
      ),
    );
  }
}
