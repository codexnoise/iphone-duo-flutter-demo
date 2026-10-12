# SPEC — Demo: app Flutter adaptativa para iPhone Duo, usando las 3 tools de IA de Flutter

## Propósito

Construir una app Flutter pequeña que corra en el **simulador del iPhone Duo** y
se **adapte a las poses del plegable** (cerrado / abierto / plegado parcial),
construida de principio a fin usando **obligatoriamente** las tres herramientas de
IA de Flutter que se mostraron en la serie de posts:

1. **Dart & Flutter MCP server** — el agente se conecta a la app corriendo,
   inspecciona el árbol de widgets y los errores de runtime, y ejecuta tests.
2. **Agentic Hot Reload** — el agente itera en vivo sobre la app mientras se
   cambian las poses del Duo, sin reiniciar.
3. **Agent Skills** — el agente construye la UI siguiendo los skills oficiales
   (layout responsivo, fix de layout, y testing), no a criterio propio.

Este es el cierre de la trilogía "Flutter + IA": las tres herramientas trabajando
juntas sobre el hardware más nuevo de Apple.

> Regla rectora: **ningún paso de UI o de corrección se hace "a mano" por el
> agente sin pasar por el skill o la tool correspondiente.** Si el agente puede
> resolver algo con un skill o con el MCP, debe hacerlo por esa vía. El valor del
> demo es mostrar las tools en acción, no solo el resultado.

---

## Los dos demos anteriores (fuente de verdad)

Este demo se apoya en los dos repos públicos de la serie. El agente debe leerlos
(vía `gh`) en lugar de reconstruir el contexto de memoria — la carpeta local
`responsive_skill_demo/` ya no existe.

| Repo | Qué aporta a este demo |
|---|---|
| [`codexnoise/agent-skills-flutter-demo`](https://github.com/codexnoise/agent-skills-flutter-demo) | El método: el resultado esperado del skill `flutter-build-responsive-layout` y el formato de evidencia (`evidence/`, scorecard, árboles de widgets con cabecera). El catálogo de productos se sustituyó por el de CDs (ver más abajo). |
| [`codexnoise/agentic-hot-reload-flutter-demo`](https://github.com/codexnoise/agentic-hot-reload-flutter-demo) | El setup que ya funcionó: FVM con `.fvmrc`, `.mcp.json` a nivel proyecto, permisos MCP pre-aprobados, el loop DTD → `get_runtime_errors` → fix → `hot_reload`, y la prueba de estado con un contador. |

### Lo que se reusa del demo de Agent Skills

> **Actualizado (2026-10-06):** el catálogo genérico de productos se sustituyó
> por un catálogo de 5 CDs (datos CC0 de Discogs, portadas generadas por código),
> descrito en `docs/superpowers/specs/2026-10-02-cd-catalog-duo-design.md`. De este
> demo se reusa el **método**, no el código: el prompt al skill que no dicta la
> solución, la trazabilidad de los skills instalados (hashes) y el formato de
> `evidence/` (cabecera con herramienta, dispositivo + pose y fecha). La deuda de
> 7.7 px de la Toma B ya no aplica: cambió la UI.

### Lo que se reusa del demo de Agentic Hot Reload

- **FVM obligatorio:** `.fvmrc` con la versión fijada y **siempre**
  `fvm flutter …` / `fvm dart …`, nunca los binarios globales (el global de esta
  Mac es 3.44.9).
- **`.mcp.json` de proyecto** con el server `dart` lanzado vía `fvm dart mcp-server`
  (sin rutas absolutas, sin API keys).
- **Herramientas MCP verificadas** en ese setup: `dtd` (`listDtdUris` +
  `connect`), `get_runtime_errors`, `widget_inspector`, `hot_reload`,
  `hot_restart`, `analyze_files`. Las de ciclo de vida (`launch_app`,
  `list_running_apps`, `stop_app`, `get_app_logs`) **no se expusieron**: la app
  se lanza a mano con `fvm flutter run`.
- **`flutter_driver_command`** solo funciona con `enableFlutterDriverExtension()`
  en el entrypoint — que es justo lo que configura el skill
  `flutter-add-integration-test` (Fase 5).
- **Prueba de estado:** un contador visible que sobrevive al `hot_reload` (y se
  pierde con `hot_restart`). Aquí se usa para demostrar que el cambio de pose +
  hot reload no reinicia la app.
- **El reload por DTD no imprime nada en la terminal** de `flutter run`: la
  grabación tiene que ser split-screen (simulador + Claude Code).

---

## Contexto de ejecución

Esto corre en **Claude Code (terminal)** en la Mac del desarrollador
(Apple Silicon, confirmado). Trabaja por fases, en orden, deteniéndote en cada ⏸
para reportar antes de seguir.

### Estado del entorno (verificado; actualizado 2026-10-06)

| Requisito | Esperado | Encontrado | |
|---|---|---|---|
| Flutter / Dart | 3.47+ / 3.13+ | **3.47.4 / 3.13.3** vía FVM (`.fvmrc`); el global sigue en 3.44.9 | ✅ |
| macOS | 26.6+ | 26.6.2, arm64 | ✅ |
| Xcode | 27.1 beta | **27.1 (27A9269)** en `/Applications/Xcode-beta.app`, seleccionado; 26.5 sigue en `/Applications/Xcode.app` | ✅ |
| Runtime iOS 27.1 + device type Duo | sí | iOS 27.1 (24A94401) + `iPhone Duo` (`8A082039-2934-44E1-B92C-CDCE41CBC5C1`) | ✅ |
| Dart MCP | conectado | `.mcp.json` del proyecto: `fvm dart mcp-server --enable run_tests` (server 1.1.2) | ✅ |

La UI del simulador del Duo en Xcode 27.1 es **DeviceHub**
(`/Applications/Xcode-beta.app/Contents/Applications/DeviceHub.app`).
`open -a Simulator` abre el de Xcode 26.5, que no conoce el Duo.

---

## Fase 0 — Verificación de entorno (bloqueante)

⏸ Ejecuta y reporta:

```bash
fvm flutter --version      # debe ser 3.47.x o superior
fvm dart --version         # Dart 3.13+
sw_vers                    # macOS 26.6 o superior
xcode-select -p            # debe apuntar a Xcode 27.1 beta
xcodebuild -version        # Xcode 27.1 (beta)
xcrun simctl list runtimes # debe listar iOS 27.1
xcrun simctl list devicetypes | grep -i duo
xcrun simctl list devices | grep -i duo
fvm dart mcp-server --help # el server viene con el SDK
```

Fija la versión del proyecto con FVM (se hace dentro del proyecto en la Fase 2,
aquí solo se instala):
```bash
fvm install 3.47.x   # la última 3.47 estable disponible
```

Requisitos que deben cumplirse TODOS antes de continuar:
- Flutter **3.47+** (resuelve el bug de `lipo -verify_arch` de Xcode 27 que
  rompía el build en 3.44 con "does not contain architectures arm64 x86_64";
  flutter/flutter#188461, fix en 3.47.0).
- macOS 26.6+ y Mac Apple Silicon (ya confirmado).
- Xcode 27.1 beta **seleccionado** (`sudo xcode-select -s /Applications/Xcode-beta.app`)
  con runtime iOS 27.1 instalado. Compilar contra el iOS 27.1 SDK no es un paso
  aparte: ocurre solo si este es el Xcode activo.
- Simulador del iPhone Duo disponible.

Si el simulador Duo NO aparece pero el runtime iOS 27.1 SÍ está:
```bash
xcrun simctl create "iPhone Duo" <device-type-id> <ios-27.1-runtime-id>
```
(obtén los IDs de `xcrun simctl list devicetypes` y `... list runtimes`).

Si falta algo de lo bloqueante, DETENTE y repórtalo. No improvises con versiones
viejas ni apliques el workaround de `ARCHS=arm64` de 3.44 — el objetivo es usar
3.47 donde el fix ya está.

---

## Fase 1 — Scaffold del proyecto

(Va antes de configurar las tools porque tanto los skills como el `.mcp.json` se
instalan a nivel proyecto.)

```bash
cd ~/Documents/projects
fvm spawn 3.47.x create duo_adaptive_demo   # o: fvm flutter create con la versión ya fijada
cd duo_adaptive_demo
fvm use 3.47.x                               # escribe .fvmrc
git init && git add -A && git commit -m "chore: flutter create scaffold"
```

Ajustes obligatorios (el agente los aplica y explica cada uno):
- **Deployment target iOS 15.0** en el proyecto Xcode (Flutter 3.47 usa Swift
  Package Manager y `foldable` lo soporta: no hay `ios/Podfile`). Dos motivos:
  Xcode 27 convierte en error cualquier target
  < 15.0 (antes era warning), y el paquete `foldable` exige 15.0. Ojo: si Xcode
  27 "actualiza" el proyecto, puede poner `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`
  (= 17.0); fijarlo explícito en 15.0.
- Añadir **`foldable: ^1.0.4`** a `pubspec.yaml` — necesario porque Flutter no
  popula `MediaQuery.displayFeatures` en iOS (`dart:ui` lo documenta como
  "populated only on Android"); el paquete trae ángulo de bisagra, postura y
  regiones reservadas por platform channel.
- Envolver la app en **`FoldableProvider(child: MaterialApp(...))`**.
- **(Actualizado)** Baseline del catálogo de CDs, con la estructura del documento
  de diseño (`docs/superpowers/specs/2026-10-02-cd-catalog-duo-design.md`):
  ```
  lib/
  ├── main.dart                     # FoldableProvider + MaterialApp
  ├── models/album.dart             # Album.fromJson (formato Discogs)
  ├── data/album_repository.dart    # assets/discogs/*.json
  ├── state/selection.dart          # disco seleccionado + favoritos
  └── screens/catalog_screen.dart   # baseline: lista plana de CDs
  ```
  El `catalog_screen.dart` arranca **sin responsividad**. La responsividad la pone
  el skill en la Fase 3.
- Añadir un **marcador de estado** visible: un contador de favoritos en el
  `AppBar` (un `StatefulWidget` mínimo). Es la prueba en cámara de que ni el
  cambio de pose ni el hot reload reinician la app (patrón del contador del demo
  de hot reload).

⏸ Reporta `fvm flutter analyze` limpio, `.fvmrc` con 3.47.x y el commit hecho.

---

## Fase 2 — Configurar las tools de IA (obligatorio antes de codear UI)

### 2.1 Agent Skills — instalar los skills oficiales

`flutter/agent-plugins` ya incluye **todos** los skills `dart-*` (incluido
`dart-add-unit-test`), así que basta con un solo origen — instalar también
`dart-lang/skills` duplicaría skills. El Skills CLI 1.0 viene en el SDK desde
Flutter 3.44.7:

```bash
# Lo que se usó (el CLI del SDK exige elegir el agente):
fvm dart run skills@ add flutter/agent-plugins --all --agent claude
```

Commitear `.claude/skills/` (la carpeta que Claude Code carga; `--agent generic`
instalaría en `.agents/skills/`, que Claude Code no lee) y
`.config/dart_skills/skills_config.json`, que deja trazado el hash de cada skill
(el CLI del SDK no genera `skills-lock.json`).

Los skills que este demo USARÁ obligatoriamente:
- `flutter-build-responsive-layout` — construir el layout adaptativo (Fase 3).
- `flutter-fix-layout-issues` — corregir overflows / constraints vía MCP (Fase 4).
- `dart-add-unit-test` — unit test de la lógica pose → layout (Fase 5).
- `flutter-add-widget-test` — test de componente (Fase 5).
- `flutter-add-integration-test` — test end-to-end con Flutter Driver (Fase 5).

⏸ Verifica e informa:
```bash
ls -la .claude/skills
find .claude/skills -name "SKILL.md" | sort
cat .config/dart_skills/skills_config.json
```
Pregúntale además al agente: "¿Qué skills tienes disponibles para layout y
testing? Resume qué hace cada uno." Reporta la respuesta (sirve de evidencia para
el post).

### 2.2 Dart & Flutter MCP server

Igual que en el demo de hot reload: registrarlo **a nivel proyecto** con
`.mcp.json` versionado, apuntando al `dart` de FVM. **`--enable run_tests` es
obligatorio:** en `dart_mcp_server` 1.1.2 `run_tests` (y `launch_app`,
`dart_fix`…) viene deshabilitado por defecto y sin el flag no aparece:

```json
{
  "mcpServers": {
    "dart": {
      "type": "stdio",
      "command": "fvm",
      "args": ["dart", "mcp-server", "--enable", "run_tests"]
    }
  }
}
```

Luego:
1. **Reiniciar Claude Code desde la raíz de `duo_adaptive_demo/`** (un MCP nuevo
   no se carga en la sesión en curso) y aprobar el server `dart`.
2. Pre-aprobar los permisos en `.claude/settings.local.json` para que no frenen
   las tomas:
   ```json
   "mcp__dart__dtd", "mcp__dart__get_runtime_errors",
   "mcp__dart__widget_inspector", "mcp__dart__analyze_files",
   "mcp__dart__hot_reload", "mcp__dart__run_tests",
   "mcp__dart__flutter_driver_command"
   ```
   (`hot_restart` queda fuera a propósito: destruye la prueba de estado.)
3. Verificar con `claude mcp list` / `/mcp` que `dart` aparece conectado.

⏸ Reporta la **lista real de herramientas** que expone el server con 3.47 y
confirma que existen, como mínimo: descubrimiento (`dtd`), árbol de widgets
(`widget_inspector` o el nombre que tenga en esta versión), errores de runtime
(`get_runtime_errors`), `hot_reload` y **ejecución de tests** (`run_tests`). Si
alguna no está, repórtalo textual: el checklist final depende de ellas.

### 2.3 Agentic Hot Reload

No requiere instalación aparte: es el MCP disparando `hot_reload` por DTD sobre
la app que corre en la terminal de `fvm flutter run`. Se confirma en la Fase 3.

---

## Fase 3 — La app base + primer loop con las tools

### 3.1 Construcción OBLIGATORIA vía Agent Skill

El layout responsivo NO se escribe a criterio del agente. Se construye invocando
`flutter-build-responsive-layout` sobre `catalog_screen.dart`, con un prompt que
no dicte la solución:

```
Haz responsiva la pantalla de catálogo: lista de una columna cuando el espacio
es angosto y grilla multicolumna cuando es amplio.
```

Resultado esperado (lo que el skill exige, y lo que produjo en la Toma B):
- `LayoutBuilder` + `constraints.maxWidth` (no `MediaQuery.of().size`).
- Breakpoints con nombre, sin números mágicos.
- Decisión basada en el **espacio disponible**, no en tipo de dispositivo.

> Esto es clave para el Duo: el plegable cambia el espacio disponible en vivo, así
> que basar el layout en constraints (no en "es tablet/phone") es exactamente lo
> que hace que la app se adapte bien al plegado. En el post de Agent Skills la
> ventaja del `LayoutBuilder` "solo se veía en el árbol" (en el iPhone 17 ambas
> tomas mostraban lista). Aquí por fin se ve en pantalla.

**Chequeo de breakpoint contra el Duo** (medidas de terceros, a confirmar en el
simulador): externa ≈ **466 pt** de ancho → lista; interna ≈ **626 pt** en
vertical / **≈ 890 pt** en horizontal → grilla con un breakpoint de 600. En
vertical el margen es de solo ~26 pt: confirma el `maxWidth` real que recibe el
`LayoutBuilder` en cada pose (vía MCP) antes de dar el breakpoint por bueno. Si
el skill elige otro valor, no se toca a mano: se reporta.

### 3.2 Correr y conectar las tools

```bash
fvm flutter run -d <udid-del-iPhone-Duo>   # esta terminal queda viva toda la demo
```

Con la app corriendo (pose: cerrado, pantalla externa):
- **MCP:** pedir al agente "Lista las apps Dart corriendo en este workspace."
  Debe usar `dtd` (`listDtdUris` + `connect`) sin pedir la URI a mano. Luego
  captura el árbol de widgets inicial → `evidence/widget-tree-closed.txt`.
- **Agentic Hot Reload:** poner el contador de favoritos en un valor visible
  (ej. 7); el agente hace un cambio pequeño (p. ej. el título del `AppBar`) y
  dispara `hot_reload`. La terminal no imprime nada (esperado); la prueba es el
  simulador: cambio aplicado y contador intacto.

Formato de cada archivo de evidencia (igual que el demo de Agent Skills):
cabecera con herramienta usada, dispositivo + pose, fecha, y luego el árbol
resumido con observaciones.

⏸ Reporta: árbol de widgets capturado + confirmación de hot reload con estado
preservado en el simulador Duo.

---

## Fase 4 — Adaptación a las poses del plegable

Aquí está el corazón del demo: la app reacciona a abrir / cerrar / plegar.

### 4.1 Integrar las poses con `foldable`

El agente usa el paquete `foldable` (`DuoMediaQuery`, `FoldAwareBuilder`,
`Foldable.hingeStatusStream` → `closed` / `partiallyOpen` / `fullyOpen`) y lo
combina con el `LayoutBuilder` del skill: el espacio disponible decide lista vs
grilla; la postura y las regiones reservadas deciden **dónde no poner contenido**.

La lógica pose + ancho → modo de layout va en una **función pura** (p. ej.
`lib/layout/layout_mode.dart`), sin widgets, para poder unit-testearla en la
Fase 5.

Comportamiento objetivo:
- **Cerrado (externa 5.4"):** lista compacta de una columna.
- **Abierto (interna 7.6"):** grilla multicolumna.
- **Plegado parcial:** ningún `ProductCard` cruza el pliegue. Las regiones
  reservadas del iOS 27.1 SDK son la **división** (el pliegue, ~40 pt de ancho)
  y la **oclusión** (la cámara FaceTime interna).

Detalles del paquete que hay que respetar:
- Por defecto `bridgeMode: none` → **no** publica nada en
  `MediaQuery.displayFeatures`. Si se quiere usar `displayFeatures` (o widgets
  de Flutter que lo lean), hay que activarlo explícitamente; si no, leer las
  regiones desde la API del paquete.
- Las regiones reservadas **llegan con retraso** respecto a la bisagra (de ms a
  ~1 s según la acción): decidir con `posture`, no solo con `isActive`.
- Sin el iOS 27.1 SDK las listas de regiones llegan vacías.

### 4.2 Iterar con Agentic Hot Reload sobre cada pose

Las poses **solo se cambian a mano** en la UI de Device Hub (abrir, cerrar,
rotar, plegar): `simctl` no tiene subcomando de postura ni hay API de XCTest
para eso. Así que el loop es: el desarrollador cambia la pose → el agente lee el
estado con el MCP → ajusta → `hot_reload`. Documentar cada ajuste. El contador
de favoritos debe sobrevivir a todo el recorrido de poses.

### 4.3 Verificar con el MCP en cada pose

Para cada pose, el agente captura el árbol de widgets vía MCP y confirma que la
estructura cambia como se espera (`LayoutBuilder` → `ListView` vs `GridView`),
anotando el `maxWidth` que recibió el `LayoutBuilder`. Guardar:
- `evidence/widget-tree-closed.txt`
- `evidence/widget-tree-open.txt` (vertical y horizontal)
- `evidence/widget-tree-partial.txt`

**Overflows → `flutter-fix-layout-issues`, obligatoriamente.** Con la UI de CDs
no se anticipa ningún overflow concreto: se corrige lo que el MCP encuentre (en la
práctica, 3 px en el panel del disco con el Duo cerrado en horizontal). Loop: `get_runtime_errors` con `clearRuntimeErrors: true` → el skill
diagnostica con el árbol → fix → `hot_reload` → `get_runtime_errors` otra vez,
debe volver vacío. Guardar ambas lecturas en `evidence/runtime-errors-before.txt`
y `evidence/runtime-errors-after.txt`.

⏸ Reporta: capturas de pantalla de cada pose (las hace el desarrollador; el
agente no puede sacarlas) + árboles de widgets + `maxWidth` por pose + cualquier
fix aplicado (y por qué skill).

---

## Fase 5 — Testing con skills + ejecución vía MCP

El demo no está completo sin pruebas, y se generan con skills.

### 5.1 Unit test (vía `dart-add-unit-test`)

Sobre la función pura pose + ancho → modo de layout de la Fase 4.1: cubre
cerrado, abierto, plegado parcial y los anchos alrededor del breakpoint.

### 5.2 Widget test (vía `flutter-add-widget-test`)

Verifica que, dado un ancho angosto (p. ej. 466), se renderiza el carrusel; y
dado un ancho amplio (p. ej. 890 y 669), los dos paneles sin overflow.

### 5.3 Integration test (vía `flutter-add-integration-test`)

El skill configura `integration_test` + Flutter Driver: crea
`lib/main_test.dart` con `enableFlutterDriverExtension()` y añade `Key`s a los
widgets clave. Con eso, `flutter_driver_command` del MCP pasa a funcionar (en el
demo de hot reload fallaba por no tenerlo) y el agente explora el flujo antes de
escribir el test. Flujo a cubrir: abrir catálogo → marcar un favorito → el
contador sube.

Limitación honesta: el test **no puede cambiar la pose** (no hay API). Corre en
la pose en que esté el simulador; documentarlo en el test y en el README.

### 5.4 Ejecutar los tests vía el MCP

Los tests se corren con la herramienta de testing del Dart & Flutter MCP server
(`run_tests`), no solo `flutter test` a mano, y el agente analiza los resultados.
Si en la Fase 2.2 se vio que `run_tests` no está expuesto, se reporta textual y
se corre `fvm flutter test` dejando claro que fue el fallback.

⏸ Reporta: archivos de test creados (y con qué skill), y el resultado de la
ejecución vía MCP.

---

## Fase 6 — Captura para el contenido

Material para el eventual post (formato por decidir: video o carrusel):
- Grabación **split-screen** (simulador Duo + Claude Code): el reload por DTD no
  deja rastro en la terminal, así que sin el panel del agente parece un corte de
  edición. El "wow": abrir el plegable y ver la lista convertirse en grilla con
  el contador intacto.
- Capturas de cada pose.
- Recorte de la terminal mostrando al agente usando las tools (skill invocado,
  MCP capturando el árbol, hot reload disparado, tests corriendo).
- Los árboles de widgets y lecturas de runtime errors de cada pose.
- `README.md` con la misma estructura que los dos repos anteriores (TL;DR,
  requisitos, cómo se usó cada tool, evidencia, reproducirlo).

**No publicar el repo** (crear remoto, push, hacerlo público) sin confirmación
explícita del desarrollador.

⏸ Entrega un resumen final: qué se construyó, qué tool/skill se usó en cada paso,
y qué material quedó capturado.

---

## Las 3 tools de IA — uso obligatorio por fase (checklist)

Este es el punto innegociable del demo. Cada herramienta DEBE aparecer en acción:

- [ ] **Agent Skills** — `flutter-build-responsive-layout` construyó el layout
      (Fase 3), `flutter-fix-layout-issues` corrigió el overflow (Fase 4),
      `dart-add-unit-test` + `flutter-add-widget-test` +
      `flutter-add-integration-test` crearon los tests (Fase 5).
- [ ] **Dart & Flutter MCP server** — descubrió la app vía DTD, capturó árboles
      de widgets y errores de runtime en cada pose, y ejecutó los tests
      (Fases 3, 4, 5).
- [ ] **Agentic Hot Reload** — iteró la UI en vivo al cambiar las poses sin
      reiniciar la app; el contador de favoritos lo prueba (Fases 3 y 4).

Si al final del demo alguna de las tres no se usó de forma visible, el demo no
cumple su objetivo y hay que ajustarlo.

---

## Problemas conocidos (anticipados)

- **Build falla con error de `lipo` / arquitecturas:** estás en Flutter < 3.47
  (o usando el `flutter` global en vez del de FVM). Sube a 3.47+.
- **Error de deployment target:** algún pod o el proyecto quedó < 15.0, o Xcode
  27 lo subió a 17.0 al migrar. Fijar 15.0 explícito.
- **El agente pide la URI del DTD a mano:** el MCP está corriendo con un `dart`
  que no es el de FVM. Revisar `.mcp.json`.
- **La terminal no imprime nada cuando el agente recarga:** esperado, el reload
  entra por DTD. Mirar el simulador.
- **El hot reload no hace nada:** se cerró la terminal de `fvm flutter run`; el
  reload por MCP muere con ella.
- **La app corre pero no reacciona al plegado:** falta `foldable` o el
  `FoldableProvider`. Si lo que no llega son los `displayFeatures`, es
  `bridgeMode: none` (default).
- **Las regiones reservadas llegan vacías:** no se compiló con el iOS 27.1 SDK
  (Xcode activo incorrecto). Revisar `xcode-select -p`.
- **La interna en vertical sigue mostrando lista:** el `maxWidth` real quedó
  por debajo del breakpoint (margen de ~26 pt). Reportar el valor medido; no
  ajustar el breakpoint a mano.
- **No se puede automatizar el cambio de pose:** limitación actual de Xcode
  27.1 (sin `simctl` ni XCTest). Se hace a mano en Device Hub.
- **`flutter_driver_command` falla con "extension is not enabled":** falta
  correr con `lib/main_test.dart`.
- **El simulador Duo no aparece:** falta seleccionar/instalar el runtime iOS
  27.1, o crearlo con `xcrun simctl create`.
- **Todo es beta** (Xcode 27.1): puede haber inestabilidad; reintentar y reportar
  el error textual en vez de improvisar.

---

## Reglas de oro

- Las tres tools de IA son de uso **obligatorio y visible**. No se saltan.
- Nada de UI o fixes "a mano" cuando existe un skill o tool para ello.
- Siempre `fvm flutter` / `fvm dart`; nunca los binarios globales.
- Nunca `hot_restart` durante las tomas: destruye la prueba de estado.
- Trabajo por fases, con parada y reporte en cada ⏸.
- Toda la evidencia (árboles, runtime errors, capturas, tests) se guarda en
  `evidence/`.
- Flutter 3.47+ es obligatorio; no bajar a 3.44 para este demo.
- Si algo beta falla, reportar el error textual, no inventar un workaround
  silencioso.
