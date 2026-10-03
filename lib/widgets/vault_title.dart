import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Encabezado de la app: "• ARCHIVE / DISCOTHEQUE" sobre "Curated Vault".
class VaultTitle extends StatelessWidget {
  const VaultTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Vault.mint,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 6),
            ),
            const SizedBox(width: 6),
            Text(
              'ARCHIVE / DISCOTHEQUE',
              style: ledgerLabel(fontSize: 10, color: Vault.ochre),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Curated Vault', style: serifTitle(24, italic: true)),
      ],
    );
  }
}
