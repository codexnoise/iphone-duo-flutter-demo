import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/album_palettes.dart';
import '../models/album.dart';

/// Portada abstracta dibujada por código en el estilo de las referencias de
/// Stitch: retícula fina, anillos concéntricos, dos barras diagonales y un medio
/// círculo. La composición sale del id del release, así que es estable.
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
    final w = size.width;
    final h = size.height;
    final s = size.shortestSide;
    final random = math.Random(seed);

    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);

    final grid = Paint()
      ..color = palette.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(Offset(w * i / 6, 0), Offset(w * i / 6, h), grid);
    }

    final center = Offset(
      w * (0.35 + random.nextDouble() * 0.3),
      h * (0.3 + random.nextDouble() * 0.15),
    );
    for (var i = 4; i >= 1; i--) {
      canvas.drawCircle(
        center,
        s * 0.09 * i,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014
          ..color = i.isEven ? palette.primary : palette.accent,
      );
    }
    canvas
      ..drawCircle(center, s * 0.05, Paint()..color = palette.accent)
      ..drawCircle(center, s * 0.02, Paint()..color = const Color(0xFF111111));

    canvas
      ..save()
      ..translate(center.dx, center.dy + s * 0.12)
      ..rotate(-math.pi / 3 + random.nextDouble() * 0.5)
      ..drawRect(
        Rect.fromCenter(
          center: Offset(0, -s * 0.06),
          width: s * 1.8,
          height: s * 0.1,
        ),
        Paint()..color = palette.accent,
      )
      ..drawRect(
        Rect.fromCenter(
          center: Offset(0, s * 0.07),
          width: s * 1.8,
          height: s * 0.07,
        ),
        Paint()..color = palette.primary,
      )
      ..restore();

    final base = Offset(w * (0.3 + random.nextDouble() * 0.3), h * 0.84);
    canvas
      ..drawArc(
        Rect.fromCircle(center: base, radius: s * 0.12),
        0,
        math.pi,
        true,
        Paint()..color = palette.primary,
      )
      ..drawLine(
        Offset(base.dx - s * 0.15, base.dy),
        Offset(base.dx + s * 0.35, base.dy),
        Paint()
          ..color = palette.accent
          ..strokeWidth = s * 0.008,
      );
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.seed != seed;
}
