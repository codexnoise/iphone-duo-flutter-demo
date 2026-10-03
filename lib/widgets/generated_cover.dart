import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/album_palettes.dart';
import '../models/album.dart';

/// Portada abstracta dibujada por código. La composición sale del id del
/// release, así que cada disco tiene siempre la misma.
class GeneratedCover extends StatelessWidget {
  const GeneratedCover({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        size: Size.infinite,
        painter: _CoverPainter(paletteFor(album.id), album.id),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.palette, this.seed);

  final AlbumPalette palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final random = math.Random(seed);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.background,
            Color.lerp(palette.background, palette.primary, 0.55)!,
          ],
        ).createShader(rect),
    );

    final center = Offset(
      size.width * (0.3 + random.nextDouble() * 0.4),
      size.height * (0.25 + random.nextDouble() * 0.2),
    );
    final radius = size.shortestSide * 0.32;
    canvas.drawCircle(center, radius, Paint()..color = palette.accent);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.012
      ..color = palette.background.withValues(alpha: 0.35);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 4, ring);
    }

    final band = Paint()..color = palette.primary.withValues(alpha: 0.85);
    final bandHeight = size.height * 0.07;
    canvas
      ..save()
      ..translate(size.width / 2, size.height * 0.72)
      ..rotate(-0.35 + random.nextDouble() * 0.7);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, i * bandHeight * 1.6),
          width: size.longestSide * 1.6,
          height: bandHeight,
        ),
        band,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.seed != seed;
}
