import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marcador de estado: si este número sobrevive a un cambio de pose o a un
/// hot reload, la app no se reinició.
class FavoritesBadge extends StatelessWidget {
  const FavoritesBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Vault.hairline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 16, color: Vault.mint),
              const SizedBox(width: 6),
              Text(
                '$count',
                key: const Key('favorites-count'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
