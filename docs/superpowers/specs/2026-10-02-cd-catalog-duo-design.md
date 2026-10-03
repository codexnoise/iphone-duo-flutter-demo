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
`assets/discogs/<release_id>.json`. El script guarda **solo los campos CC0** que
usa la app (título, artistas, año, país, sellos, formatos, géneros, estilos,
tracklist, créditos, notas); descarta las URLs de imágenes y los datos de
comunidad y de marketplace, que no son CC0. La app nunca llama a la red.

## Sistema visual

Referencias generadas con Google Stitch en `docs/design/stitch/` (pantallas por
pose + `DESIGN.md`, sistema "Archival Modernist"). Se toman como referencia
visual; el código no se usa.

- **Paleta:** lienzo `#1C1A19`, superficies `#252220` / `#2E2A28`, líneas de 1 px
  `#3A3533`; acentos menta `#2EC4B6`, ocre `#FFD166`, bermellón `#E76F51`, teal
  profundo `#0E3B43`, salvia `#8AB17D`; texto `#F4F1EA` / `#A8A29E` / `#6E6763`.
- **Tipografía:** Bodoni Moda para títulos de disco (la última palabra en
  cursiva menta) y Plus Jakarta Sans para todo lo demás; las etiquetas van en
  mayúsculas con tracking amplio. Ambas son OFL y se empaquetan como fuentes
  variables en `assets/fonts/` (el grosor se fija con `fontVariations`).
- **Encabezado:** "• ARCHIVE / DISCOTHEQUE" sobre *Curated Vault* en serif
  cursiva; el contador de favoritos en una pastilla a la derecha.
- **Componentes:** pastillas con borde fino ("CD · ALBUM", "CAT. …"), pestañas
  segmentadas con la activa en menta, filas de registro con línea inferior
  (posición en gris granito, duración en gris piedra), riel con miniaturas
  circulares y el rótulo vertical "ARCHIVAL".
- **Portadas:** composición Bauhaus por código (anillos concéntricos, dos barras
  diagonales, medio círculo, retícula fina) con la paleta de cada disco.

De las referencias de Stitch **no** se toman: los datos que inventó (vinilo,
RPM, matriz, condición, fidelidad de audio), la reproducción de audio ni la
barra de navegación inferior.

## Experiencia por pose

El modo de layout lo decide el **espacio disponible** (`LayoutBuilder` →
`constraints.maxWidth`) contra un breakpoint con nombre; la postura del plegable
solo decide dónde **no** poner contenido. El valor del breakpoint lo elige el skill
`flutter-build-responsive-layout` (su valor por defecto es 600); si elige otro, se
reporta y no se ajusta a mano.

### Compacto (ancho < breakpoint) — p. ej. cerrado, externa en vertical (~466 pt)

Referencia: `docs/design/stitch/closed-carousel.png` y `closed-details-sheet.png`.

- Encabezado *Curated Vault* con el contador de favoritos.
- `PageView` horizontal, un disco por página: portada enmarcada (borde fino),
  artista en ocre, título en serif, "año · país" y las pastillas de formato y
  catálogo.
- Debajo del `PageView`, fijos: indicador de páginas (5 puntos, el activo en
  menta), el botón de favorito del disco actual y el botón "VER FICHA Y TRACKS",
  que abre la ficha (mismo contenido que el panel derecho del modo de dos
  paneles) en una hoja deslizable.

### Dos paneles (ancho ≥ breakpoint) — p. ej. abierto (669 pt vertical, ~890 pt horizontal)

Referencia: `docs/design/stitch/open-portrait.png` y `open-landscape.png`.

- **Riel izquierdo:** miniaturas circulares de las 5 portadas (la seleccionada
  con anillo menta) y el rótulo vertical "ARCHIVAL"; tocar una cambia el disco.
- **Panel izquierdo (héroe):** portada en arco con un CD asomando por detrás;
  debajo, artista en ocre, título en serif, "año · país · sello", las pastillas
  "CD · ALBUM" y "CAT. …" y el botón de favorito.
- **Panel derecho (detalle):** pestañas segmentadas **Tracks N · Créditos ·
  Ficha · Notas** y, al pie, "DATOS DE DISCOGS (CC0)".
  - *Tracks:* filas de registro con posición y título; la duración se muestra
    solo si viene en el dato.
  - *Créditos:* nombre y rol (`extraartists`); si no hay, "Sin créditos en
    Discogs".
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
assets/fonts/                   # Bodoni Moda y Plus Jakarta Sans (OFL) + licencias
assets/discogs/
├── <release_id>.json           # 5 archivos, solo campos CC0 de Discogs
└── ATTRIBUTION.md
lib/
├── main.dart                   # FoldableProvider + MaterialApp (tema oscuro)
├── models/album.dart           # Album, Track, Credit + fromJson (formato Discogs)
├── data/album_repository.dart  # carga los JSON desde assets
├── data/album_palettes.dart    # paleta de portada por release_id
├── layout/layout_mode.dart     # función pura: (ancho, postura, pliegue) → modo
├── state/selection.dart        # disco seleccionado + favoritos (ChangeNotifier)
├── theme/app_theme.dart        # tokens "Archival Modernist", tema y estilos de texto
├── screens/catalog_loader.dart # carga los discos, pantalla de error, dueño de Selection
├── screens/catalog_screen.dart # LayoutBuilder → CoverCarousel | dos paneles
└── widgets/
    ├── favorites_badge.dart    # contador ❤️ N en pastilla
    ├── favorite_button.dart    # botón de favorito del disco actual
    ├── vault_title.dart        # encabezado "ARCHIVE / DISCOTHEQUE · Curated Vault"
    ├── album_title.dart        # título en serif con la última palabra en cursiva menta
    ├── archive_chip.dart       # pastilla con borde fino
    ├── pose_badge.dart         # texto de diagnóstico (postura · ancho · modo), legible por MCP
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
