/// Lógica de layout del catálogo. Dart puro: no importa Flutter ni `foldable`,
/// para poder probarse sin widgets.
library;

/// Ancho disponible a partir del cual el catálogo pasa a dos paneles.
const double largeScreenMinWidth = 600.0;

enum LayoutMode { compact, dualPane }

/// Postura de la bisagra, independiente del paquete que la reporte.
enum FoldPosture { closed, partiallyOpen, fullyOpen, unknown }

class CatalogLayout {
  const CatalogLayout.compact()
      : mode = LayoutMode.compact,
        leftPaneWidth = null,
        gapWidth = 0;

  const CatalogLayout.dualPane({
    required double this.leftPaneWidth,
    this.gapWidth = 0,
  }) : mode = LayoutMode.dualPane;

  final LayoutMode mode;

  /// Ancho del lado izquierdo (riel + panel del disco); null en compacto.
  final double? leftPaneWidth;

  /// Franja sin contenido entre los dos paneles: el ancho del pliegue.
  final double gapWidth;

  @override
  bool operator ==(Object other) =>
      other is CatalogLayout &&
      other.mode == mode &&
      other.leftPaneWidth == leftPaneWidth &&
      other.gapWidth == gapWidth;

  @override
  int get hashCode => Object.hash(mode, leftPaneWidth, gapWidth);

  @override
  String toString() =>
      'CatalogLayout(${mode.name}, left: $leftPaneWidth, gap: $gapWidth)';
}

/// Decide el layout a partir del ancho disponible, la postura y, si se
/// conoce, la región vertical del pliegue ([foldLeft]–[foldRight], en las
/// mismas coordenadas que [width]).
///
/// El ancho decide entre compacto y dos paneles. La postura y el pliegue solo
/// deciden dónde se separan los paneles: plegado a medias, exactamente en el
/// pliegue; en cualquier otro caso, por la mitad.
CatalogLayout layoutFor({
  required double width,
  required FoldPosture posture,
  double? foldLeft,
  double? foldRight,
}) {
  if (width <= largeScreenMinWidth) return const CatalogLayout.compact();

  if (posture == FoldPosture.partiallyOpen &&
      foldLeft != null &&
      foldRight != null &&
      foldLeft > 0 &&
      foldRight > foldLeft &&
      foldRight < width) {
    return CatalogLayout.dualPane(
      leftPaneWidth: foldLeft,
      gapWidth: foldRight - foldLeft,
    );
  }
  return CatalogLayout.dualPane(leftPaneWidth: width / 2);
}
