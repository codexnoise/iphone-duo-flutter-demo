import 'package:flutter/material.dart';

import '../data/products.dart';
import '../widgets/favorites_counter.dart';
import '../widgets/product_card.dart';

/// Ancho disponible a partir del cual el catálogo pasa de lista a grilla.
const double largeScreenMinWidth = 600.0;

/// Ancho máximo de cada tarjeta en la grilla; el número de columnas sale solo.
const double _gridMaxCardWidth = 360.0;

/// Proporción ancho/alto de cada celda de la grilla.
const double _gridCardAspectRatio = 2.4;

const EdgeInsets _contentPadding = EdgeInsets.all(12);

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [FavoritesCounter()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > largeScreenMinWidth) {
            return _buildGrid();
          }
          return _buildList();
        },
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: _contentPadding,
      itemCount: kProducts.length,
      itemBuilder: (context, index) {
        return ProductCard(product: kProducts[index]);
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: _contentPadding,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _gridMaxCardWidth,
        childAspectRatio: _gridCardAspectRatio,
        crossAxisSpacing: 12,
      ),
      itemCount: kProducts.length,
      itemBuilder: (context, index) {
        return ProductCard(product: kProducts[index]);
      },
    );
  }
}
