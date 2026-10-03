import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'screens/catalog_loader.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DuoAdaptiveApp());
}

class DuoAdaptiveApp extends StatelessWidget {
  const DuoAdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FoldableProvider(
      child: MaterialApp(
        title: 'CD Catalog',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const CatalogLoader(),
      ),
    );
  }
}
