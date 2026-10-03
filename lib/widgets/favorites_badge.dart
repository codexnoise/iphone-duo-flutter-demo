import 'package:flutter/material.dart';

/// Marcador de estado: si este número sobrevive a un cambio de pose o a un
/// hot reload, la app no se reinició.
class FavoritesBadge extends StatelessWidget {
  const FavoritesBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 18),
          const SizedBox(width: 4),
          Text('$count', key: const Key('favorites-count')),
        ],
      ),
    );
  }
}
