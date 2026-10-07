# Curated Vault — catálogo de CDs adaptativo para iPhone Duo (Flutter 3.47)

Cierre de la serie "Flutter + IA": una app pequeña que corre en el simulador del
**iPhone Duo** y se adapta a sus poses (cerrado, abierto, plegado a medias),
construida de principio a fin con las **tres herramientas de IA de Flutter**:

1. **Agent Skills** — los skills oficiales de `flutter/agent-plugins` escribieron
   el layout adaptativo, el fix de overflow y los tests.
2. **Dart & Flutter MCP server** — el agente descubrió la app por DTD, leyó el
   árbol de widgets, los errores de runtime y las medidas de cada pose, y corrió
   los tests.
3. **Agentic Hot Reload** — el agente iteró sobre la app viva mientras se
   cambiaba la pose del Duo, sin reiniciarla.

## TL;DR

- **Duo cerrado:** carrusel de portadas. **Abierto:** riel + disco + ficha en dos
  paneles. **Plegado a medias:** los paneles se separan exactamente en el pliegue
  (lado a lado si el pliegue es vertical, apilados en "modo mesa" si es horizontal).
- El layout lo decide el **espacio disponible** (`LayoutBuilder`, breakpoint de
  600 pt); la postura y el pliegue (paquete `foldable`) solo deciden dónde se
  separan los paneles.
- El estado (disco seleccionado y favoritos) **sobrevive** a los cambios de pose
  y al hot reload.
- 5 discos reales con datos **CC0 de Discogs**; las portadas se **dibujan por
  código** (las imágenes de portada no son CC0).

## Requisitos

| Requisito | Versión | Cómo verificar |
|---|---|---|
| Flutter / Dart | **3.47.4 / 3.13.3** vía FVM (`.fvmrc`) | `fvm flutter --version` |
| macOS | 26.6+ en Apple Silicon | `sw_vers` |
| Xcode | **27.1 beta** seleccionado | `xcode-select -p`, `xcodebuild -version` |
| Simulador | runtime **iOS 27.1** + dispositivo **iPhone Duo** | `xcrun simctl list devices \| grep -i duo` |
| Agente | Claude Code con el server `dart` de `.mcp.json` | `/mcp` |

Flutter 3.47 trae el fix de `lipo -verify_arch` que rompía el build con Xcode 27
en 3.44. El proyecto usa Swift Package Manager (no hay `Podfile`); el deployment
target iOS 15.0 está en el proyecto de Xcode.

## La app

| Disco | Release Discogs | Edición |
|---|---|---|
| Gorillaz — *Gorillaz* (2001) | 4214311 | CD Argentina, Parlophone |
| Daft Punk — *Random Access Memories* (2013) | 13115020 | CD Europa, Columbia |
| Sal y Mileto — *Disko 0* (2001) | 9100081 | CD Ecuador, autoeditado |
| Gondwana — *Alabanza* (2000) | 11066248 | CD Chile, BMG |
| Cultura Profética — *La Dulzura* (2010) | 8172924 | CD Puerto Rico, La Mafafa |

- Datos: `tool/fetch_discogs.dart` descarga los releases una vez y guarda **solo
  los campos CC0** en `assets/discogs/`. La app no usa la red. Atribución en
  [`assets/discogs/ATTRIBUTION.md`](assets/discogs/ATTRIBUTION.md).
- Diseño: referencias generadas con Google Stitch en
  [`docs/design/stitch/`](docs/design/stitch/) (sistema "Archival Modernist").
  Se tomaron paleta, tipografía (Bodoni Moda + Plus Jakarta Sans, OFL) y
  componentes; no el código ni los datos que Stitch inventó.
- Diseño y plan completos: [`docs/superpowers/specs/`](docs/superpowers/specs/) y
  [`docs/superpowers/plans/`](docs/superpowers/plans/).

```
lib/
├── main.dart · main_test.dart (entrypoint con Flutter Driver)
├── models/album.dart              # Album.fromJson (formato Discogs)
├── data/                          # repositorio de assets + paletas
├── state/selection.dart           # disco seleccionado + favoritos
├── layout/layout_mode.dart        # función pura: ancho + postura + pliegue → layout
├── screens/                       # CatalogLoader, CatalogScreen
├── theme/app_theme.dart           # tokens "Archival Modernist"
└── widgets/                       # carrusel, riel, panel del disco, detalle, portada…
```

## Cómo se usó cada tool

### Agent Skills

Instalados con el CLI del SDK en `.claude/skills/` (25 skills de
`flutter/agent-plugins`; hashes en `.config/dart_skills/skills_config.json`):

```bash
fvm dart run skills@ add flutter/agent-plugins --all --agent claude
```

| Skill | Qué hizo | Commit |
|---|---|---|
| `flutter-build-responsive-layout` | `LayoutBuilder` + breakpoint `largeScreenMinWidth = 600`: carrusel ↔ dos paneles | `1cb1437` |
| `flutter-build-responsive-layout` | Panel del disco: portada al lado en espacio ancho y bajo (modo mesa) | `29d2ca6` |
| `flutter-fix-layout-issues` | Overflow de 3 px en el panel del disco con el Duo cerrado en horizontal | `bfe6db3` |
| `dart-add-unit-test` | Tests de `Album.fromJson`, `Selection` y `layoutFor` | `56bf87c`, `7888944`, `91790ed`, `c826f07` |
| `flutter-add-widget-test` | Carrusel / dos paneles / favorito / estado / panel del disco | `60bda3e` |
| `flutter-add-integration-test` | Flutter Driver + flujo de favoritos | `1936d29` |

### Dart & Flutter MCP server

`.mcp.json` registra `fvm dart mcp-server --enable run_tests`. **`run_tests` viene
deshabilitado por defecto** en `dart_mcp_server` 1.1.2; sin ese flag no aparece.
Las herramientas de ciclo de vida (`launch_app`, `list_running_apps`…) también
vienen apagadas: la app se lanza a mano con `fvm flutter run`.

| Herramienta | Uso | Evidencia |
|---|---|---|
| `dtd` | Descubrir y conectar la app sin pedir la URI | todas |
| `widget_inspector` | Árbol de widgets por pose | [`widget-tree-closed.txt`](evidence/widget-tree-closed.txt), [`widget-tree-open.txt`](evidence/widget-tree-open.txt), [`widget-tree-partial.txt`](evidence/widget-tree-partial.txt) |
| `vm_service` | `maxWidth` del `LayoutBuilder` por pose; insets de iOS; texto del `PoseBadge` | [`widget-tree-open.txt`](evidence/widget-tree-open.txt), [`runtime-errors-after.txt`](evidence/runtime-errors-after.txt) |
| `get_runtime_errors` | Overflow antes / vacío después en cada pose | [`runtime-errors-before.txt`](evidence/runtime-errors-before.txt), [`runtime-errors-after.txt`](evidence/runtime-errors-after.txt) |
| `analyze_files` | Tras cada cambio | — |
| `run_tests` | 39 unit + widget tests | [`tests.txt`](evidence/tests.txt) |
| `flutter_driver_command` | Exploración del flujo de favoritos con `lib/main_test.dart` | [`tests.txt`](evidence/tests.txt) |

### Agentic Hot Reload

- **Prueba de estado:** con *Disko 0* y 2 favoritos, el agente cambió el
  encabezado y disparó `hot_reload` por DTD: el texto cambió, el disco y el
  contador siguieron intactos ([`widget-tree-closed.txt`](evidence/widget-tree-closed.txt)).
- **El momento del demo:** el layout de dos paneles entró por `hot_reload` con el
  Duo abierto; la app pasó del carrusel a los dos paneles **sin reiniciarse**,
  con el mismo disco y los mismos favoritos.
- El reload por DTD no imprime nada en la terminal de `flutter run`; se ve en el
  simulador y en el panel del agente.

## Medidas por pose (vía MCP)

| Pose | Ventana | Body (`LayoutBuilder`) | Layout |
|---|---|---|---|
| Cerrado, vertical | 466 × 678 | 466 × 606 | Carrusel |
| Cerrado, horizontal | 678 × 466 | 678 × 394 | Dos paneles |
| Abierto, vertical | 669 × 951 | 669 × 797 | Dos paneles |
| Abierto, horizontal | 951 × 669 | 867 × 597 (iOS reserva 84 pt a la derecha) | Dos paneles |
| Plegado a medias, horizontal | 951 × 669 | 867 pt | Lado a lado, pliegue x 456–496 |
| Plegado a medias, vertical | 669 × 951 | 669 pt | Apilados, pliegue y 302–342 |

Con la interna en vertical el pliegue del Duo es **horizontal** (solo en
horizontal queda vertical, en el centro). Las medidas de terceros del SPEC para
la interna (626 / 890 pt) no coinciden con el simulador.

## Limitaciones y hallazgos

- Las poses **solo se cambian a mano** en DeviceHub: no hay subcomando de
  `simctl` ni API de XCTest para la bisagra. El integration test corre en la pose
  en que esté el simulador.
- `run_tests` del MCP no expone `-d`: con varios dispositivos conectados no puede
  correr el integration test; se usó `fvm flutter test … -d <udid>`.
- Cambiar la forma de una clase con instancias `const` vivas (`CatalogLayout`) no
  entra con hot reload (`reloadSources -32603`); hizo falta un `hot_restart`
  fuera de las tomas.
- `MediaQuery.paddingOf(context).top` dentro del body de un `Scaffold` con
  `AppBar` vale 0: para convertir la región del pliegue a coordenadas del body
  hay que leer el inset fuera del `Scaffold`. Lo detectó una captura, no el MCP:
  el layout era válido, solo estaba 82 pt corrido.
- `open -a Simulator` abre el simulador de Xcode 26.5 (y `flutter run` también lo
  abre). La UI correcta del Duo es DeviceHub de Xcode 27.1; cerrar el simulador
  viejo apaga el Duo.
- Flutter no publica el pliegue en iOS (`displayFeatures` vacío): se usa el
  paquete `foldable` sin `bridgeMode`.

## Reproducirlo

```bash
fvm install                      # instala la versión de .fvmrc (3.47.4)
fvm flutter pub get
xcrun simctl boot <udid-del-iPhone-Duo>
open /Applications/Xcode-beta.app/Contents/Applications/DeviceHub.app
fvm flutter run -d <udid-del-iPhone-Duo>          # esta terminal queda viva
```

Después, en Claude Code abierto en la raíz del proyecto: "Lista las apps Dart
corriendo en este workspace" (el agente usa `dtd`), y cambia la pose en DeviceHub.

Tests:

```bash
fvm flutter test                                                  # o MCP run_tests
fvm flutter test integration_test/app_test.dart -d <udid>
```

Para ver la insignia de diagnóstico (postura · ancho · modo · pliegue):
`fvm flutter run --dart-define=SHOW_POSE_BADGE=true -d <udid>`.

## Créditos de datos

Datos de [Discogs](https://www.discogs.com) bajo CC0 — ver
[`assets/discogs/ATTRIBUTION.md`](assets/discogs/ATTRIBUTION.md). Fuentes Bodoni
Moda y Plus Jakarta Sans bajo SIL Open Font License (`assets/fonts/OFL-*.txt`).
