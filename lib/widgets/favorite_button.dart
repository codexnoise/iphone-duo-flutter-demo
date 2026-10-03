import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón de favorito del disco actual.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: isFavorite ? 'Quitar de favoritos' : 'Marcar como favorito',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Vault.mint,
        side: const BorderSide(color: Vault.hairline),
      ),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }
}
