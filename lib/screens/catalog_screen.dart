import 'package:flutter/material.dart';

import '../data/products.dart';
import '../widgets/favorites_counter.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [FavoritesCounter()],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: kProducts.length,
        itemBuilder: (context, index) {
          final product = kProducts[index];
          return ProductCard(product: product);
        },
      ),
    );
  }
}
