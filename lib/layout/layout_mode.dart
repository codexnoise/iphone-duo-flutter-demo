/// Lógica de layout del catálogo. Dart puro: no importa Flutter ni `foldable`,
/// para poder probarse sin widgets.
library;

/// Ancho disponible a partir del cual el catálogo pasa a dos paneles.
const double largeScreenMinWidth = 600.0;

enum LayoutMode { compact, dualPane }

/// Cómo se reparten los dos paneles.
enum PaneAxis {
  /// Lado a lado: riel + panel del disco a la izquierda, detalle a la derecha.
  sideBySide,

  /// Apilados: riel + panel del disco arriba, detalle abajo (pliegue horizontal).
  stacked,
}

/// Postura de la bisagra, independiente del paquete que la reporte.
enum FoldPosture { closed, partiallyOpen, fullyOpen, unknown }

class CatalogLayout {
  const CatalogLayout.compact()
      : mode = LayoutMode.compact,
        axis = PaneAxis.sideBySide,
        firstPaneExtent = null,
        gapExtent = 0;

  const CatalogLayout.sideBySide({
    required double this.firstPaneExtent,
    this.gapExtent = 0,
  })  : mode = LayoutMode.dualPane,
        axis = PaneAxis.sideBySide;

  const CatalogLayout.stacked({
    required double this.firstPaneExtent,
    this.gapExtent = 0,
  })  : mode = LayoutMode.dualPane,
        axis = PaneAxis.stacked;

  final LayoutMode mode;
  final PaneAxis axis;

  /// Ancho (lado a lado) o alto (apilados) del primer panel, que incluye el
  /// riel y el panel del disco; null en compacto.
  final double? firstPaneExtent;

  /// Franja sin contenido entre los dos paneles: el grosor del pliegue.
  final double gapExtent;

  @override
  bool operator ==(Object other) =>
      other is CatalogLayout &&
      other.mode == mode &&
      other.axis == axis &&
      other.firstPaneExtent == firstPaneExtent &&
      other.gapExtent == gapExtent;

  @override
  int get hashCode => Object.hash(mode, axis, firstPaneExtent, gapExtent);

  @override
  String toString() => 'CatalogLayout(${mode.name}, ${axis.name}, '
      'first: $firstPaneExtent, gap: $gapExtent)';
}

/// Decide el layout a partir del espacio disponible, la postura y, si se
/// conoce, la región del pliegue en las mismas coordenadas que [width] y
/// [height]: vertical ([foldLeft]–[foldRight]) u horizontal
/// ([foldTop]–[foldBottom]).
///
/// El ancho decide entre compacto y dos paneles. La postura y el pliegue solo
/// deciden cómo se reparten: plegado a medias, separados exactamente en el
/// pliegue (lado a lado si es vertical, apilados si es horizontal); en
/// cualquier otro caso, lado a lado por la mitad.
CatalogLayout layoutFor({
  required double width,
  double height = double.infinity,
  required FoldPosture posture,
  double? foldLeft,
  double? foldRight,
  double? foldTop,
  double? foldBottom,
}) {
  if (width <= largeScreenMinWidth) return const CatalogLayout.compact();

  if (posture == FoldPosture.partiallyOpen) {
    if (_isInside(foldLeft, foldRight, width)) {
      return CatalogLayout.sideBySide(
        firstPaneExtent: foldLeft!,
        gapExtent: foldRight! - foldLeft,
      );
    }
    if (_isInside(foldTop, foldBottom, height)) {
      return CatalogLayout.stacked(
        firstPaneExtent: foldTop!,
        gapExtent: foldBottom! - foldTop,
      );
    }
  }
  return CatalogLayout.sideBySide(firstPaneExtent: width / 2);
}

/// Si la franja [start]–[end] cae dentro de un espacio finito de [extent].
bool _isInside(double? start, double? end, double extent) =>
    start != null &&
    end != null &&
    extent.isFinite &&
    start > 0 &&
    end > start &&
    end < extent;
