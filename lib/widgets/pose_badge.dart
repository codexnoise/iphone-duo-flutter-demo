import 'package:flutter/material.dart';

import '../layout/layout_mode.dart';

/// Texto de diagnóstico con la pose y el layout actuales. Al ser un `Text`,
/// el agente lo lee por MCP en el árbol de widgets.
class PoseBadge extends StatelessWidget {
  const PoseBadge({
    super.key,
    required this.posture,
    required this.width,
    required this.layout,
  });

  final FoldPosture posture;
  final double width;
  final CatalogLayout layout;

  @override
  Widget build(BuildContext context) {
    final left = layout.leftPaneWidth;
    final label = [
      posture.name,
      '${width.toStringAsFixed(0)} pt',
      layout.mode.name,
      if (left != null && layout.gapWidth > 0)
        'pliegue ${left.toStringAsFixed(0)}–'
            '${(left + layout.gapWidth).toStringAsFixed(0)}',
    ].join(' · ');
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            key: const Key('pose-badge'),
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
