# Diseño — Catálogo de CDs para iPhone Duo

**Fecha:** 2026-10-02
**Estado:** aprobado en conversación, pendiente de revisión escrita
**Reemplaza:** el catálogo genérico de productos (`Product` / `ProductCard`) del
`SPEC-iphone-duo-demo.md`. Todo lo demás del SPEC (las 3 tools de IA, FVM, fases,
evidencia, reglas de oro) sigue vigente.

## Propósito

Una app de catálogo para melómanos: ver CDs con su portada, tracklist, créditos y
ficha técnica. Básica en funcionalidad, pero visualmente llamativa, inspirada en
el patrón de la app *Wonderous* sobre el Duo: pieza a pantalla completa cuando el
teléfono está cerrado, dos paneles separados por el pliegue cuando está abierto.

La app es el vehículo del demo; el objetivo sigue siendo mostrar Agent Skills,
Dart & Flutter MCP server y Agentic Hot Reload en acción.

## Contenido y licencias

- **Fuente:** API pública de Discogs (`api.discogs.com`), sin autenticación
  (25 req/min por IP, `User-Agent` propio obligatorio).
- **Licencia:** los datos usados (títulos, fechas, formato, tracklist, créditos,
  notas, artistas, sellos) son **CC0** según los términos de la API de Discogs.
- **Portadas:** **no** se usan las imágenes de Discogs (no son CC0). Cada portada
  se genera por código (`CustomPaint`) con una paleta propia por disco; no imita
  la portada original.
- **Letras:** no se incluyen (copyright). No hay pestaña de letras.
- **Atribución:** la app muestra "Datos de Discogs (CC0)" y el repo incluye
  `assets/discogs/ATTRIBUTION.md` con los IDs y URLs de cada release.

### Discos (5)

| Disco | Release Discogs | Edición |
|---|---|---|
| Gorillaz — *Gorillaz* (2001) | 4214311 | CD Argentina, Parlophone |
| Daft Punk — *Random Access Memories* (2013) | 13115020 | CD Europa, Columbia |
| Sal y Mileto — *Disko 0* (2001) | 9100081 | CD Ecuador, autoeditado |
| Gondwana — *Alabanza* (2000) | 11066248 | CD Chile, BMG |
| Cultura Profética — *La Dulzura* (2010) | 8172924 | CD Puerto Rico, La Mafafa |

Los datos se descargan **una vez** con `tool/fetch_discogs.dart` y se versionan en
`assets/discogs/<release_id>.json` tal cual los devuelve la API. La app nunca
llama a la red.

## Experiencia por pose

El modo de layout lo decide el **espacio disponible** (`LayoutBuilder` →
`constraints.maxWidth`) contra un breakpoint con nombre; la postura del plegable
solo decide dónde **no** poner contenido. El valor del breakpoint lo elige el skill
`flutter-build-responsive-layout` (su valor por defecto es 600); si elige otro, se
reporta y no se ajusta a mano.

### Compacto (ancho < breakpoint) — p. ej. cerrado, externa en vertical (~466 pt)

- `PageView` horizontal a pantalla completa, un disco por página.
- Fondo: portada generada del disco.
- Encima: título del disco en serif grande, artista y año.
- Abajo: indicador de páginas (5 puntos) y un chevron que despliega la ficha del
  disco (mismo contenido que el panel derecho del modo de dos paneles) en una
  hoja deslizable.
- AppBar mínima con el contador de favoritos (❤️ N) y un botón para marcar el
  disco actual como favorito.

### Dos paneles (ancho ≥ breakpoint) — p. ej. abierto (669 pt vertical, ~890 pt horizontal)

- **Riel izquierdo:** miniaturas de las 5 portadas en vertical; tocar una cambia
  el disco seleccionado.
- **Panel izquierdo (héroe):** portada en forma de arco, un CD asomando por
  detrás, título, artista y una franja con año · país · sello.
- **Panel derecho (detalle):** pestañas **Tracks · Créditos · Ficha · Notas**.
  - *Tracks:* tarjetas oscuras con posición y título; la duración se muestra solo
    si viene en el dato.
  - *Créditos:* nombre y rol (`extraartists`).
  - *Ficha:* año, país, sello y número de catálogo, formato, géneros y estilos.
  - *Notas:* el campo `notes` de Discogs; si viene vacío, la pestaña muestra
    "Sin notas en Discogs".

### Plegado parcial

Con postura `partiallyOpen` y una región de pliegue reportada por `foldable`, los
paneles izquierdo y derecho se separan exactamente en el pliegue: ningún
contenido cruza la región de división. Mientras las regiones no llegan (llegan
con retraso respecto a la bisagra), la decisión se toma con la postura y se usa
una división al 50 %.

### Decisión registrada

La externa en horizontal mide **678 pt** (medido vía MCP), así que también
muestra dos paneles. Se acepta: es la consecuencia de decidir por espacio y no por
dispositivo, que es lo que exige el skill.

### Medidas reales confirmadas vía MCP (body del `Scaffold`)

| Pose | maxWidth × maxHeight |
|---|---|
| Interna, vertical | 669 × 813 |
| Externa, horizontal | 678 × 410 |
| Externa, vertical | pendiente de medir |
| Interna, horizontal | pendiente de medir |

## Estructura

```
tool/
└── fetch_discogs.dart          # descarga los 5 releases → assets/discogs/
assets/discogs/
├── <release_id>.json           # 5 archivos, JSON de Discogs sin modificar
└── ATTRIBUTION.md
lib/
├── main.dart                   # FoldableProvider + MaterialApp (tema oscuro)
├── models/album.dart           # Album, Track, Credit + fromJson (formato Discogs)
├── data/album_repository.dart  # carga los JSON desde assets
├── data/album_palettes.dart    # paleta de portada por release_id
├── layout/layout_mode.dart     # función pura: (ancho, postura, pliegue) → modo
├── state/selection.dart        # disco seleccionado + favoritos (ChangeNotifier)
├── screens/catalog_screen.dart # LayoutBuilder → CoverCarousel | DualPaneView
└── widgets/
    ├── generated_cover.dart    # CustomPaint de la portada
    ├── cover_carousel.dart     # modo compacto
    ├── album_hero_pane.dart    # panel izquierdo
    ├── album_detail_pane.dart  # panel derecho con pestañas
    └── album_rail.dart         # riel de miniaturas
```

Cada unidad tiene una sola responsabilidad:

- `Album.fromJson` no conoce Flutter (solo `dart:core`), así se testea con
  `package:test`.
- `layout_mode.dart` no importa widgets: recibe números y un enum de postura,
  devuelve un modo. Es lo que cubre el unit test.
- Los widgets reciben un `Album` y no saben de dónde salió.

## Flujo de datos y estado

1. `main` arranca; `AlbumRepository.loadAll()` lee los 5 JSON desde `rootBundle`
   y devuelve `List<Album>` en el orden de la tabla.
2. `Selection` (un `ChangeNotifier` creado **por encima** del `LayoutBuilder`)
   guarda el índice del disco seleccionado y el conjunto de favoritos.
3. `CatalogScreen` lee el ancho y la postura, llama a `layoutModeFor(...)` y
   construye la vista correspondiente; ambas vistas leen y escriben en la misma
   `Selection`.

Consecuencia: si se está en *Random Access Memories* con el teléfono cerrado y se
abre, la vista de dos paneles arranca en *Random Access Memories*, y el contador
de favoritos sigue igual. Esa es la **prueba de estado** del demo (sustituye al
contador del SPEC original): sobrevive a cambios de pose y a `hot_reload`, y se
pierde con `hot_restart`.

## Manejo de errores

- **Campo ausente en el JSON** (duración, créditos, notas, estilos): se omite el
  elemento visual, no se inventa ni se muestra un valor vacío.
- **Asset que no carga o JSON inválido:** la app muestra una pantalla de error
  con el `release_id` afectado. No hay reintentos (los assets son locales; un
  fallo es un bug de empaquetado, no un estado transitorio).
- **`foldable` sin datos** (dispositivo no plegable o regiones vacías): se usa
  solo el ancho; sin pliegue conocido, la división es al 50 %.

## Cómo se construye con las 3 tools

| Paso | Tool / skill |
|---|---|
| Baseline: lista plana de CDs (sin responsividad) | a mano, igual que el baseline del SPEC |
| Carrusel ↔ dos paneles con `LayoutBuilder` y breakpoint con nombre | `flutter-build-responsive-layout` |
| Lógica de pose + pliegue en `layout_mode.dart` | integración con `foldable` (Fase 4) |
| Overflows o problemas de constraints que aparezcan | `flutter-fix-layout-issues` + MCP (`get_runtime_errors`, `widget_inspector`) |
| Iteración visual en vivo (paletas, tipografía, separación en el pliegue) | `hot_reload` vía DTD, sin reiniciar |
| Unit tests de `layout_mode.dart` y `Album.fromJson` | `dart-add-unit-test` |
| Widget test: 466 pt → carrusel; 890 pt → dos paneles sin overflow | `flutter-add-widget-test` |
| Integration test: abrir disco → marcar favorito → el contador sube | `flutter-add-integration-test` |
| Ejecución de todos los tests | `run_tests` del MCP |

Ya no se espera el overflow de 7.7 px de la Toma B (cambió la UI). Si
`flutter-fix-layout-issues` no tiene nada que corregir, se reporta así; no se
fabrica un bug.

## Fuera de alcance

Compras o carrito, búsqueda, discografía en línea de tiempo, letras, llamadas a la
red en tiempo de ejecución, más de 5 discos, imágenes reales de portada.

## Impacto en el repo actual

- Se eliminan `models/product.dart`, `data/products.dart`,
  `widgets/product_card.dart` y `widgets/favorites_counter.dart`.
- `SPEC-iphone-duo-demo.md` se actualiza: la sección "Lo que se reusa del demo de
  Agent Skills" pasa a decir que solo se reusa el método (skills + evidencia), no
  el código; la Fase 1 describe el baseline de CDs; la Fase 4 deja de anticipar
  el overflow de 7.7 px.
- El historial de git conserva el catálogo de productos (commits `56d8841` y
  `b85aed9`) como referencia.
