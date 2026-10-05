import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Título de disco en Bodoni Moda con la última palabra en cursiva menta.
class AlbumTitle extends StatelessWidget {
  const AlbumTitle({
    super.key,
    required this.title,
    required this.fontSize,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  final String title;
  final double fontSize;
  final TextAlign textAlign;

  /// Si se fija, el título se recorta con "…" al llegar a ese número de líneas.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final split = title.lastIndexOf(' ');
    return Text.rich(
      TextSpan(
        style: serifTitle(fontSize),
        children: [
          if (split <= 0)
            TextSpan(text: title)
          else ...[
            TextSpan(text: title.substring(0, split)),
            TextSpan(
              text: title.substring(split),
              style: serifTitle(fontSize, italic: true, color: Vault.mint),
            ),
          ],
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
