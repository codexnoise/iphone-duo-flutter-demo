# Catálogo de CDs para iPhone Duo — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el catálogo genérico de productos por un catálogo de 5 CDs (datos CC0 de Discogs, portadas generadas por código) que muestra un carrusel a pantalla completa con el Duo cerrado y dos paneles separados por el pliegue con el Duo abierto.

**Architecture:** Los datos se descargan una vez a `assets/discogs/` y la app nunca usa la red. `CatalogLoader` carga los discos y es dueño de `Selection` (disco seleccionado + favoritos), que vive por encima del `LayoutBuilder` para sobrevivir a los cambios de pose. `CatalogScreen` decide carrusel o dos paneles por ancho disponible; una función pura (`layoutFor`) añade la postura y el pliegue.

**Tech Stack:** Flutter 3.47.4 / Dart 3.13.3 vía FVM, paquete `foldable` 1.0.5, Dart & Flutter MCP server 1.1.2, Agent Skills de `flutter/agent-plugins`, Xcode 27.1 beta, simulador iPhone Duo (`8A082039-2934-44E1-B92C-CDCE41CBC5C1`).

**Spec:** `docs/superpowers/specs/2026-10-02-cd-catalog-duo-design.md`

## Reglas que aplican a todas las tareas

- Siempre `fvm flutter …` / `fvm dart …`. Nunca los binarios globales.
- Nunca `hot_restart` mientras la app esté viva para la demo: destruye la prueba de estado.
- Las tareas marcadas **[skill]** se hacen invocando el skill indicado con la herramienta Skill. El código que aparece en esas tareas es el contenido que se le pide al skill o el resultado esperado; si el skill produce algo distinto pero válido, se conserva lo del skill y se reporta la diferencia.
- Las tareas marcadas **[usuario]** necesitan al desarrollador: lanzar `fvm flutter run` en su terminal o cambiar la pose en DeviceHub. No se puede automatizar.
- El simulador se muestra con `open /Applications/Xcode-beta.app/Contents/Applications/DeviceHub.app`. No cerrar ninguna ventana del simulador con la app viva.
- Raíz del proyecto para las tools MCP: `file:///Users/giftpoint/Documents/projects/iphone-duo-flutter-demo`.
- Todos los commits terminan con el trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Formato de cada archivo de `evidence/`: cabecera con herramienta usada, dispositivo + pose, fecha; luego el contenido resumido y observaciones.

## Mapa de archivos

| Archivo | Responsabilidad | Tarea |
|---|---|---|
| `tool/fetch_discogs.dart` | Descarga los 5 releases y guarda solo campos CC0 | 1 |
| `assets/discogs/<id>.json`, `ATTRIBUTION.md` | Datos versionados | 1 |
| `lib/models/album.dart` | `Album`, `Track`, `Credit`, `Album.fromJson` (Dart puro) | 2 |
| `lib/data/album_repository.dart` | Carga los JSON desde assets | 3 |
| `lib/data/album_palettes.dart` | Paleta de portada por release | 3 |
| `lib/state/selection.dart` | Disco seleccionado + favoritos | 4 |
| `lib/theme/app_theme.dart` | Tema oscuro y estilo de títulos | 5 |
| `lib/widgets/generated_cover.dart` | Portada por `CustomPaint` | 5 |
| `lib/widgets/favorites_badge.dart` | Contador ❤️ N | 5 |
| `lib/screens/catalog_loader.dart` | Carga, error, dueño de `Selection` | 5 |
| `lib/screens/catalog_screen.dart` | Baseline (5) → carrusel (7) → responsivo (9) → pliegue (11) | 5, 7, 9, 11 |
| `lib/widgets/album_detail_pane.dart` | Pestañas Tracks / Créditos / Ficha / Notas | 6 |
| `lib/widgets/cover_carousel.dart` | Modo compacto | 7 |
| `lib/widgets/album_hero_pane.dart`, `album_rail.dart` | Panel izquierdo y riel | 8 |
| `lib/layout/layout_mode.dart` | Función pura ancho + postura + pliegue → layout | 11 |
| `lib/widgets/pose_badge.dart` | Texto de diagnóstico legible por MCP | 11 |
| `test/…`, `integration_test/…`, `lib/main_test.dart` | Tests | 2, 4, 11, 13, 14 |
| `evidence/…`, `README.md`, `SPEC-iphone-duo-demo.md` | Evidencia y documentación | 7, 10, 12, 15, 16 |

---

## Parte A — Baseline (app detenida)

Si `fvm flutter run` sigue vivo con el catálogo de productos, el desarrollador lo detiene con `q` antes de empezar: los assets nuevos requieren un build completo.

### Task 1: Datos de Discogs

**Files:**
- Create: `tool/fetch_discogs.dart`
- Create: `assets/discogs/4214311.json`, `13115020.json`, `9100081.json`, `11066248.json`, `8172924.json` (generados)
- Create: `assets/discogs/ATTRIBUTION.md`
- Modify: `pubspec.yaml` (sección `flutter:`)

- [ ] **Step 1: Escribir el script de descarga**

`tool/fetch_discogs.dart`:

```dart
// Descarga los releases del catálogo desde la API pública de Discogs y guarda
// solo los campos con licencia CC0 en assets/discogs/<id>.json.
//
// Uso: fvm dart run tool/fetch_discogs.dart
import 'dart:convert';
import 'dart:io';

const releaseIds = [4214311, 13115020, 9100081, 11066248, 8172924];
const userAgent = 'DuoCdDemo/0.1 +https://github.com/codexnoise';

/// Campos de primer nivel que se conservan. Quedan fuera imágenes, datos de
/// comunidad y de marketplace, que no son CC0.
const keptFields = [
  'id',
  'uri',
  'title',
  'artists',
  'year',
  'released',
  'country',
  'labels',
  'formats',
  'genres',
  'styles',
  'tracklist',
  'extraartists',
  'notes',
];

/// Claves que se conservan dentro de cada elemento de las listas anidadas.
const keptNestedKeys = {
  'artists': ['name', 'anv'],
  'labels': ['name', 'catno'],
  'formats': ['name', 'qty', 'descriptions'],
  'tracklist': ['position', 'title', 'duration', 'type_'],
  'extraartists': ['name', 'anv', 'role', 'tracks'],
};

Future<void> main() async {
  final client = HttpClient();
  final outDir = Directory('assets/discogs')..createSync(recursive: true);
  for (final id in releaseIds) {
    final request = await client.getUrl(
      Uri.parse('https://api.discogs.com/releases/$id'),
    );
    request.headers.set(HttpHeaders.userAgentHeader, userAgent);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      stderr.writeln('release $id: HTTP ${response.statusCode}');
      exitCode = 1;
      continue;
    }
    final release = jsonDecode(body) as Map<String, dynamic>;
    final trimmed = <String, dynamic>{
      for (final field in keptFields)
        if (release.containsKey(field)) field: _trim(field, release[field]),
    };
    File('${outDir.path}/$id.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(trimmed)}\n',
    );
    stdout.writeln('release $id: ${trimmed['title']}');
    // Límite sin autenticación: 25 peticiones por minuto.
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  client.close();
}

Object? _trim(String field, Object? value) {
  final keys = keptNestedKeys[field];
  if (keys == null || value is! List) return value;
  return [
    for (final item in value.whereType<Map<String, dynamic>>())
      {
        for (final key in keys)
          if (item.containsKey(key)) key: item[key],
      },
  ];
}
```

- [ ] **Step 2: Ejecutar el script**

Run: `fvm dart run tool/fetch_discogs.dart`
Expected (5 líneas, ~15 s):

```
release 4214311: Gorillaz
release 13115020: Random Access Memories
release 9100081: Disko 0
release 11066248: Alabanza - Por La Fuerza De La Razón
release 8172924: La Dulzura
```

- [ ] **Step 3: Verificar los archivos**

Run: `ls -la assets/discogs/ && grep -c '"images"\|"community"\|"lowest_price"' assets/discogs/*.json`
Expected: 5 archivos `.json`; el `grep -c` devuelve `0` para cada uno.

- [ ] **Step 4: Escribir la atribución**

`assets/discogs/ATTRIBUTION.md`:

```markdown
# Datos de Discogs

Los archivos `*.json` de esta carpeta vienen de la API pública de Discogs
(https://api.discogs.com) y contienen solo campos que Discogs publica bajo
licencia CC0 ("No Rights Reserved"): títulos, artistas, fechas, país, sellos,
formatos, géneros, estilos, tracklist, créditos y notas.

No se incluyen imágenes de portada, datos de comunidad ni de marketplace. Las
portadas de la app se generan por código y no reproducen las originales.

| Archivo | Release | URL |
|---|---|---|
| `4214311.json` | Gorillaz — Gorillaz (2001) | https://www.discogs.com/release/4214311 |
| `13115020.json` | Daft Punk — Random Access Memories (2013) | https://www.discogs.com/release/13115020 |
| `9100081.json` | Sal y Mileto — Disko 0 (2001) | https://www.discogs.com/release/9100081 |
| `11066248.json` | Gondwana — Alabanza (2000) | https://www.discogs.com/release/11066248 |
| `8172924.json` | Cultura Profética — La Dulzura (2010) | https://www.discogs.com/release/8172924 |

Para regenerarlos: `fvm dart run tool/fetch_discogs.dart`.
```

- [ ] **Step 5: Declarar los assets**

En `pubspec.yaml`, dentro de la sección `flutter:` y justo debajo de `uses-material-design: true`, añadir:

```yaml
  assets:
    - assets/discogs/
```

Run: `fvm flutter pub get`
Expected: `Got dependencies!`

- [ ] **Step 6: Commit**

```bash
git add tool/fetch_discogs.dart assets/discogs pubspec.yaml
git commit -m "feat: datos CC0 de Discogs para los 5 discos del catálogo"
```

### Task 2: Modelo `Album` **[skill: dart-add-unit-test]**

**Files:**
- Create: `lib/models/album.dart`
- Test: `test/models/album_test.dart`

- [ ] **Step 1: Escribir el test que falla, invocando el skill**

Invocar `dart-add-unit-test` pidiéndole un unit test para `Album.fromJson` en `test/models/album_test.dart` con estos casos. Si el skill añade `package:test` como dev-dependency y entra en conflicto con `flutter_test`, usar `package:flutter_test/flutter_test.dart` (reexporta la misma API) y reportarlo.

```dart
import 'dart:convert';
import 'dart:io';

import 'package:duo_adaptive_demo/models/album.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixture = <String, Object>{
  'id': 42,
  'title': ' Disko 0 ',
  'year': 2001,
  'country': 'Ecuador',
  'artists': [
    {'name': 'Gondwana (4)', 'anv': ''},
  ],
  'labels': [
    {'name': 'Not On Label', 'catno': 'none'},
  ],
  'formats': [
    {
      'name': 'CD',
      'qty': '1',
      'descriptions': ['Album', 'Enhanced'],
    },
  ],
  'genres': ['Rock'],
  'styles': <String>[],
  'tracklist': [
    {'position': '', 'title': 'Lado A', 'duration': '', 'type_': 'heading'},
    {'position': '1', 'title': 'Kito Con K  ', 'duration': '', 'type_': 'track'},
    {'position': '2', 'title': 'Otra', 'duration': '3:40', 'type_': 'track'},
  ],
  'extraartists': [
    {'name': 'Noodle (2)', 'role': 'Guitar'},
  ],
  'notes':
      'Con [a=Odetta] en [url=http://x]este release[/url]. Ver [r123] también.',
};

void main() {
  group('Album.fromJson', () {
    final album = Album.fromJson(_fixture);

    test('lee los campos básicos y recorta espacios', () {
      expect(album.id, 42);
      expect(album.title, 'Disko 0');
      expect(album.year, 2001);
      expect(album.country, 'Ecuador');
      expect(album.genres, ['Rock']);
      expect(album.styles, isEmpty);
    });

    test('quita el sufijo de desambiguación de Discogs en los nombres', () {
      expect(album.artist, 'Gondwana');
      expect(album.credits.single.name, 'Noodle');
      expect(album.credits.single.role, 'Guitar');
    });

    test('trata "none" como catálogo ausente', () {
      expect(album.label, 'Not On Label');
      expect(album.catalogNumber, isNull);
    });

    test('une el formato con sus descripciones', () {
      expect(album.formats, ['CD (Album, Enhanced)']);
    });

    test('solo conserva las entradas de tipo track', () {
      expect(album.tracks.map((t) => t.title), ['Kito Con K', 'Otra']);
    });

    test('la duración vacía pasa a null', () {
      expect(album.tracks[0].duration, isNull);
      expect(album.tracks[1].duration, '3:40');
    });

    test('limpia el marcado de Discogs en las notas', () {
      expect(album.notes, 'Con Odetta en este release. Ver también.');
    });

    test('los campos ausentes no rompen el parseo', () {
      final minimal = Album.fromJson(const {'id': 1, 'title': 'X', 'year': 0});
      expect(minimal.artist, '');
      expect(minimal.year, isNull);
      expect(minimal.label, isNull);
      expect(minimal.tracks, isEmpty);
      expect(minimal.credits, isEmpty);
      expect(minimal.notes, isNull);
    });

    test('un release sin título lanza FormatException', () {
      expect(() => Album.fromJson(const {'id': 1}), throwsFormatException);
    });
  });

  group('assets de Discogs', () {
    for (final id in [4214311, 13115020, 9100081, 11066248, 8172924]) {
      test('el release $id se parsea y tiene tracks', () {
        final raw = File('assets/discogs/$id.json').readAsStringSync();
        final album = Album.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        expect(album.id, id);
        expect(album.title, isNotEmpty);
        expect(album.artist, isNotEmpty);
        expect(album.tracks, isNotEmpty);
      });
    }
  });
}
```

- [ ] **Step 2: Correr el test y ver que falla**

MCP `run_tests` con `roots: [{root: <raíz>, paths: ["test/models/album_test.dart"]}]`.
Expected: FALLA de compilación — `lib/models/album.dart` no existe.

- [ ] **Step 3: Implementar el modelo**

`lib/models/album.dart`:

```dart
/// Un disco del catálogo, parseado desde el formato de release de Discogs.
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.year,
    this.country,
    this.label,
    this.catalogNumber,
    this.formats = const [],
    this.genres = const [],
    this.styles = const [],
    this.tracks = const [],
    this.credits = const [],
    this.notes,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final title = _text(json['title']);
    if (title == null) {
      throw const FormatException('El release de Discogs no tiene título');
    }
    final year = json['year'];
    final labels = _maps(json['labels']);
    final catalogNumber = labels.isEmpty ? null : _text(labels.first['catno']);
    return Album(
      id: json['id'] as int,
      title: title,
      artist: _maps(json['artists'])
          .map((artist) => _name(artist['anv']) ?? _name(artist['name']))
          .nonNulls
          .join(', '),
      year: year is int && year > 0 ? year : null,
      country: _text(json['country']),
      label: labels.isEmpty ? null : _name(labels.first['name']),
      catalogNumber:
          catalogNumber?.toLowerCase() == 'none' ? null : catalogNumber,
      formats: [
        for (final format in _maps(json['formats']))
          if (_text(format['name']) case final name?)
            _strings(format['descriptions']).isEmpty
                ? name
                : '$name (${_strings(format['descriptions']).join(', ')})',
      ],
      genres: _strings(json['genres']),
      styles: _strings(json['styles']),
      tracks: [
        for (final track in _maps(json['tracklist']))
          if (track['type_'] == 'track')
            Track(
              position: _text(track['position']) ?? '',
              title: _text(track['title']) ?? '',
              duration: _text(track['duration']),
            ),
      ],
      credits: [
        for (final credit in _maps(json['extraartists']))
          if (_name(credit['anv']) ?? _name(credit['name']) case final name?)
            Credit(name: name, role: _text(credit['role']) ?? ''),
      ],
      notes: _notes(json['notes']),
    );
  }

  final int id;
  final String title;
  final String artist;
  final int? year;
  final String? country;
  final String? label;
  final String? catalogNumber;
  final List<String> formats;
  final List<String> genres;
  final List<String> styles;
  final List<Track> tracks;
  final List<Credit> credits;
  final String? notes;
}

class Track {
  const Track({required this.position, required this.title, this.duration});

  final String position;
  final String title;
  final String? duration;
}

class Credit {
  const Credit({required this.name, required this.role});

  final String name;
  final String role;
}

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

/// Texto recortado, o null si falta o queda vacío.
String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Discogs desambigua homónimos con un sufijo " (2)"; no se muestra.
final _disambiguation = RegExp(r' \(\d+\)$');

String? _name(Object? value) => _text(value)?.replaceFirst(_disambiguation, '');

final _namedReference = RegExp(r'\[[al]=([^\]]+)\]');
final _markupTag = RegExp(r'\[url=[^\]]*\]|\[/url\]|\[/?[biu]\]');
final _idReference = RegExp(r'\[[armlst]\d+\]');
final _repeatedSpaces = RegExp(r'[ \t]{2,}');

/// Las notas de Discogs usan un marcado propio ([a=Nombre], [url=…], [r123]).
String? _notes(Object? value) {
  final raw = _text(value);
  if (raw == null) return null;
  final cleaned = raw
      .replaceAllMapped(_namedReference, (match) => match[1]!)
      .replaceAll(_markupTag, '')
      .replaceAll(_idReference, '')
      .replaceAll(_repeatedSpaces, ' ')
      .trim();
  return cleaned.isEmpty ? null : cleaned;
}
```

- [ ] **Step 4: Correr el test y ver que pasa**

MCP `run_tests` sobre `test/models/album_test.dart`.
Expected: 14 tests, todos PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/album.dart test/models/album_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: modelo Album desde el formato de release de Discogs"
```

### Task 3: Repositorio y paletas

**Files:**
- Create: `lib/data/album_repository.dart`
- Create: `lib/data/album_palettes.dart`

- [ ] **Step 1: Escribir el repositorio**

`lib/data/album_repository.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/album.dart';

/// Releases de Discogs del catálogo, en el orden en que se muestran.
const List<int> kReleaseIds = [4214311, 13115020, 9100081, 11066248, 8172924];

class AlbumLoadException implements Exception {
  const AlbumLoadException(this.releaseId, this.cause);

  final int releaseId;
  final Object cause;

  @override
  String toString() => 'No se pudo cargar el release $releaseId: $cause';
}

class AlbumRepository {
  const AlbumRepository({this.bundle});

  /// Bundle del que se leen los assets; por defecto, [rootBundle].
  final AssetBundle? bundle;

  Future<List<Album>> loadAll() async {
    final source = bundle ?? rootBundle;
    final albums = <Album>[];
    for (final id in kReleaseIds) {
      try {
        final raw = await source.loadString('assets/discogs/$id.json');
        albums.add(Album.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (error) {
        throw AlbumLoadException(id, error);
      }
    }
    return albums;
  }
}
```

- [ ] **Step 2: Escribir las paletas**

`lib/data/album_palettes.dart`:

```dart
import 'package:flutter/material.dart';

/// Colores de la portada generada de un disco. Son propios de la app: no
/// imitan la portada original.
class AlbumPalette {
  const AlbumPalette({
    required this.background,
    required this.primary,
    required this.accent,
  });

  final Color background;
  final Color primary;
  final Color accent;
}

const Map<int, AlbumPalette> kAlbumPalettes = {
  // Gorillaz — Gorillaz
  4214311: AlbumPalette(
    background: Color(0xFF2B1B4A),
    primary: Color(0xFFE94F8A),
    accent: Color(0xFFF6C445),
  ),
  // Daft Punk — Random Access Memories
  13115020: AlbumPalette(
    background: Color(0xFF0E3B43),
    primary: Color(0xFF2EC4B6),
    accent: Color(0xFFFFD166),
  ),
  // Sal y Mileto — Disko 0
  9100081: AlbumPalette(
    background: Color(0xFF3A1010),
    primary: Color(0xFFE4572E),
    accent: Color(0xFFF3A712),
  ),
  // Gondwana — Alabanza
  11066248: AlbumPalette(
    background: Color(0xFF123524),
    primary: Color(0xFF3E8E41),
    accent: Color(0xFFF2C14E),
  ),
  // Cultura Profética — La Dulzura
  8172924: AlbumPalette(
    background: Color(0xFF40204A),
    primary: Color(0xFFF28482),
    accent: Color(0xFFF6BD60),
  ),
};

const AlbumPalette kFallbackPalette = AlbumPalette(
  background: Color(0xFF24211F),
  primary: Color(0xFF8D99AE),
  accent: Color(0xFFEDF2F4),
);

AlbumPalette paletteFor(int releaseId) =>
    kAlbumPalettes[releaseId] ?? kFallbackPalette;
```

- [ ] **Step 3: Analizar**

MCP `analyze_files` con `roots: [{root: <raíz>}]`.
Expected: `No errors`.

- [ ] **Step 4: Commit**

```bash
git add lib/data/album_repository.dart lib/data/album_palettes.dart
git commit -m "feat: repositorio de discos desde assets y paletas de portada"
```

### Task 4: Estado `Selection` **[skill: dart-add-unit-test]**

**Files:**
- Create: `lib/state/selection.dart`
- Test: `test/state/selection_test.dart`

- [ ] **Step 1: Escribir el test que falla, invocando el skill**

Invocar `dart-add-unit-test` para `Selection` en `test/state/selection_test.dart`:

```dart
import 'package:duo_adaptive_demo/state/selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Selection', () {
    test('arranca en el primer disco y sin favoritos', () {
      final selection = Selection();
      expect(selection.index, 0);
      expect(selection.favoritesCount, 0);
    });

    test('select cambia el índice y notifica', () {
      final selection = Selection();
      var notifications = 0;
      selection.addListener(() => notifications++);

      selection.select(3);

      expect(selection.index, 3);
      expect(notifications, 1);
    });

    test('select con el mismo índice no notifica', () {
      final selection = Selection();
      var notifications = 0;
      selection.addListener(() => notifications++);

      selection.select(0);

      expect(notifications, 0);
    });

    test('toggleFavorite alterna el favorito y actualiza el contador', () {
      final selection = Selection();

      selection.toggleFavorite(4214311);
      selection.toggleFavorite(8172924);
      expect(selection.isFavorite(4214311), isTrue);
      expect(selection.favoritesCount, 2);

      selection.toggleFavorite(4214311);
      expect(selection.isFavorite(4214311), isFalse);
      expect(selection.favoritesCount, 1);
    });
  });
}
```

- [ ] **Step 2: Correr el test y ver que falla**

MCP `run_tests` sobre `test/state/selection_test.dart`.
Expected: FALLA de compilación — `lib/state/selection.dart` no existe.

- [ ] **Step 3: Implementar**

`lib/state/selection.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Estado que debe sobrevivir a los cambios de pose y al hot reload: el disco
/// seleccionado y los favoritos.
class Selection extends ChangeNotifier {
  int _index = 0;
  final Set<int> _favorites = {};

  int get index => _index;

  int get favoritesCount => _favorites.length;

  bool isFavorite(int releaseId) => _favorites.contains(releaseId);

  void select(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void toggleFavorite(int releaseId) {
    if (!_favorites.remove(releaseId)) _favorites.add(releaseId);
    notifyListeners();
  }
}
```

- [ ] **Step 4: Correr el test y ver que pasa**

MCP `run_tests` sobre `test/state/selection_test.dart`.
Expected: 4 tests, todos PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state/selection.dart test/state/selection_test.dart
git commit -m "feat: estado Selection con disco seleccionado y favoritos"
```

### Task 5: Baseline — lista plana de CDs

**Files:**
- Create: `lib/theme/app_theme.dart`, `lib/widgets/generated_cover.dart`, `lib/widgets/favorites_badge.dart`, `lib/screens/catalog_loader.dart`
- Modify: `lib/screens/catalog_screen.dart` (reemplazo completo), `lib/main.dart` (reemplazo completo)
- Delete: `lib/models/product.dart`, `lib/data/products.dart`, `lib/widgets/product_card.dart`, `lib/widgets/favorites_counter.dart`

- [ ] **Step 1: Tema**

`lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

/// Serif de alto contraste que viene con iOS.
const String kDisplayFontFamily = 'Didot';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFFE4572E),
    scaffoldBackgroundColor: const Color(0xFF1C1A19),
  );
}

/// Estilo de los títulos de disco.
TextStyle displayTitleStyle(double fontSize) {
  return TextStyle(
    fontFamily: kDisplayFontFamily,
    fontFamilyFallback: const ['Georgia'],
    fontSize: fontSize,
    height: 1.0,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
```

- [ ] **Step 2: Portada generada**

`lib/widgets/generated_cover.dart`:

```dart
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
```

- [ ] **Step 3: Contador de favoritos**

`lib/widgets/favorites_badge.dart`:

```dart
import 'package:flutter/material.dart';

/// Marcador de estado: si este número sobrevive a un cambio de pose o a un
/// hot reload, la app no se reinició.
class FavoritesBadge extends StatelessWidget {
  const FavoritesBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 18),
          const SizedBox(width: 4),
          Text('$count', key: const Key('favorites-count')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Pantalla baseline (lista plana, sin responsividad)**

`lib/screens/catalog_screen.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../widgets/favorites_badge.dart';
import '../widgets/generated_cover.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    super.key,
    required this.albums,
    required this.selection,
  });

  final List<Album> albums;
  final Selection selection;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CD Catalog'),
            actions: [FavoritesBadge(count: selection.favoritesCount)],
          ),
          body: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                leading: SizedBox.square(
                  dimension: 56,
                  child: GeneratedCover(album: album),
                ),
                title: Text(album.title),
                subtitle: Text(album.artist),
                selected: index == selection.index,
                onTap: () => selection.select(index),
                trailing: IconButton(
                  icon: Icon(
                    selection.isFavorite(album.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: () => selection.toggleFavorite(album.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Loader**

`lib/screens/catalog_loader.dart`:

```dart
import 'package:flutter/material.dart';

import '../data/album_repository.dart';
import '../models/album.dart';
import '../state/selection.dart';
import 'catalog_screen.dart';

/// Carga los discos y es dueño de [Selection]. Vive por encima del layout
/// adaptativo, así que el estado sobrevive al cambio entre carrusel y dos
/// paneles.
class CatalogLoader extends StatefulWidget {
  const CatalogLoader({super.key, this.repository = const AlbumRepository()});

  final AlbumRepository repository;

  @override
  State<CatalogLoader> createState() => _CatalogLoaderState();
}

class _CatalogLoaderState extends State<CatalogLoader> {
  late final Future<List<Album>> _albums = widget.repository.loadAll();
  final Selection _selection = Selection();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: _albums,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
            ),
          );
        }
        final albums = snapshot.data;
        if (albums == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CatalogScreen(albums: albums, selection: _selection);
      },
    );
  }
}
```

- [ ] **Step 6: `main.dart`**

`lib/main.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';
import 'package:foldable/foldable.dart';

import 'screens/catalog_loader.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DuoAdaptiveApp());
}

class DuoAdaptiveApp extends StatelessWidget {
  const DuoAdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FoldableProvider(
      child: MaterialApp(
        title: 'CD Catalog',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const CatalogLoader(),
      ),
    );
  }
}
```

- [ ] **Step 7: Borrar el catálogo de productos**

```bash
git rm lib/models/product.dart lib/data/products.dart lib/widgets/product_card.dart lib/widgets/favorites_counter.dart
```

- [ ] **Step 8: Analizar y compilar**

MCP `analyze_files` → Expected: `No errors`.
Run: `fvm flutter build ios --simulator --debug`
Expected: `✓ Built build/ios/iphonesimulator/Runner.app`

- [ ] **Step 9: Commit**

```bash
git add lib
git commit -m "feat: baseline del catálogo de CDs (lista plana, sin responsividad)"
```

- [ ] **Step 10: ⏸ [usuario] Lanzar la app**

El desarrollador, en su terminal, con el Duo **cerrado y en vertical**:

```bash
fvm flutter run -d 8A082039-2934-44E1-B92C-CDCE41CBC5C1
```

Esta terminal queda viva el resto del plan.

- [ ] **Step 11: Conectar por MCP y confirmar el baseline**

MCP `dtd` `listDtdUris` → `connect` con la URI devuelta (sin pedírsela al usuario).
MCP `widget_inspector` `get_widget_tree` `summaryOnly: true`.
Expected: `CatalogLoader → CatalogScreen → Scaffold → ListView` con 5 `ListTile`.
MCP `get_runtime_errors` → Expected: sin errores.

---

## Parte B — Componentes, con Agentic Hot Reload (app viva)

Cada tarea de esta parte termina con `hot_reload` por MCP y una lectura de `get_runtime_errors`. La terminal de `flutter run` no imprime nada cuando el reload entra por DTD: la verificación es el simulador y el árbol de widgets.

### Task 6: Panel de detalle

**Files:**
- Create: `lib/widgets/album_detail_pane.dart`

- [ ] **Step 1: Escribir el widget**

`lib/widgets/album_detail_pane.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/album.dart';

/// Ficha de un disco en pestañas: tracks, créditos, ficha técnica y notas.
class AlbumDetailPane extends StatelessWidget {
  const AlbumDetailPane({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Tracks'),
                Tab(text: 'Créditos'),
                Tab(text: 'Ficha'),
                Tab(text: 'Notas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TracksTab(album: album),
                  _CreditsTab(album: album),
                  _SpecsTab(album: album),
                  _NotesTab(album: album),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Datos de Discogs (CC0)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const EdgeInsets _tabPadding = EdgeInsets.all(16);

class _TracksTab extends StatelessWidget {
  const _TracksTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: _tabPadding,
      itemCount: album.tracks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final track = album.tracks[index];
        return _InfoCard(
          leading: track.position,
          title: track.title,
          trailing: track.duration,
        );
      },
    );
  }
}

class _CreditsTab extends StatelessWidget {
  const _CreditsTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    if (album.credits.isEmpty) {
      return const Center(child: Text('Sin créditos en Discogs'));
    }
    return ListView.separated(
      padding: _tabPadding,
      itemCount: album.credits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final credit = album.credits[index];
        return _InfoCard(title: credit.name, subtitle: credit.role);
      },
    );
  }
}

class _SpecsTab extends StatelessWidget {
  const _SpecsTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (album.year case final year?) ('Año', '$year'),
      if (album.country case final country?) ('País', country),
      if (album.label case final label?) ('Sello', label),
      if (album.catalogNumber case final catalog?) ('Catálogo', catalog),
      if (album.formats.isNotEmpty) ('Formato', album.formats.join(', ')),
      if (album.genres.isNotEmpty) ('Géneros', album.genres.join(', ')),
      if (album.styles.isNotEmpty) ('Estilos', album.styles.join(', ')),
    ];
    return ListView.separated(
      padding: _tabPadding,
      itemCount: rows.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (label, value) = rows[index];
        return _InfoCard(title: value, subtitle: label);
      },
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final notes = album.notes;
    if (notes == null) {
      return const Center(child: Text('Sin notas en Discogs'));
    }
    return SingleChildScrollView(padding: _tabPadding, child: Text(notes));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? leading;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (leading case final leading?)
              SizedBox(
                width: 36,
                child: Text(leading, style: theme.textTheme.titleMedium),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (subtitle case final subtitle?)
                    Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing case final trailing?)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(trailing, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analizar**

MCP `analyze_files` → Expected: `No errors`.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/album_detail_pane.dart
git commit -m "feat: panel de detalle con pestañas de tracks, créditos, ficha y notas"
```

### Task 7: Carrusel de portadas + primera prueba de hot reload

**Files:**
- Create: `lib/widgets/cover_carousel.dart`
- Modify: `lib/screens/catalog_screen.dart` (reemplazo completo)
- Create: `evidence/widget-tree-closed.txt`

- [ ] **Step 1: Escribir el carrusel**

`lib/widgets/cover_carousel.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../theme/app_theme.dart';
import 'album_detail_pane.dart';
import 'generated_cover.dart';

/// Modo compacto: una portada a pantalla completa por disco.
class CoverCarousel extends StatefulWidget {
  const CoverCarousel({
    super.key,
    required this.albums,
    required this.selection,
  });

  final List<Album> albums;
  final Selection selection;

  @override
  State<CoverCarousel> createState() => _CoverCarouselState();
}

class _CoverCarouselState extends State<CoverCarousel> {
  // Arranca en el disco seleccionado: al volver de dos paneles se conserva.
  late final PageController _controller = PageController(
    initialPage: widget.selection.index,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails() {
    final album = widget.albums[widget.selection.index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: AlbumDetailPane(album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.albums.length,
          onPageChanged: widget.selection.select,
          itemBuilder: (context, index) {
            return _CoverPage(album: widget.albums[index]);
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PageDots(
                  count: widget.albums.length,
                  index: widget.selection.index,
                ),
                IconButton(
                  key: const Key('open-details'),
                  tooltip: 'Ver ficha',
                  color: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: _openDetails,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GeneratedCover(album: album),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.55),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  album.title,
                  textAlign: TextAlign.center,
                  style: displayTitleStyle(44),
                ),
                const SizedBox(height: 8),
                Text(
                  [album.artist, if (album.year != null) '${album.year}']
                      .join(' · '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: La pantalla muestra el carrusel (todavía sin responsividad)**

`lib/screens/catalog_screen.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';

import '../models/album.dart';
import '../state/selection.dart';
import '../widgets/cover_carousel.dart';
import '../widgets/favorites_badge.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    super.key,
    required this.albums,
    required this.selection,
  });

  final List<Album> albums;
  final Selection selection;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        final album = albums[selection.index];
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('CD Catalog'),
            actions: [
              IconButton(
                key: const Key('favorite-toggle'),
                tooltip: 'Favorito',
                icon: Icon(
                  selection.isFavorite(album.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: () => selection.toggleFavorite(album.id),
              ),
              FavoritesBadge(count: selection.favoritesCount),
            ],
          ),
          body: CoverCarousel(albums: albums, selection: selection),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Analizar y recargar**

MCP `analyze_files` → Expected: `No errors`.
MCP `hot_reload` con `clearRuntimeErrors: true`.
MCP `get_runtime_errors` → Expected: sin errores.
MCP `widget_inspector` `get_widget_tree` `summaryOnly: true` → Expected: `CatalogScreen → Scaffold → CoverCarousel → PageView`.

- [ ] **Step 4: ⏸ [usuario] Poner estado visible**

El desarrollador desliza hasta el **tercer disco** (*Disko 0*) y marca **2 favoritos** (el contador muestra `2`).

- [ ] **Step 5: Prueba de estado con hot reload**

En `lib/screens/catalog_screen.dart`, cambiar `const Text('CD Catalog')` por `const Text('Discos')`.
MCP `hot_reload`.
MCP `widget_inspector` `get_widget_tree` `summaryOnly: true`.
Expected: el `Text` del AppBar dice `Discos`, el `Text` con key `favorites-count` dice `2` y el título visible sigue siendo `Disko 0`. El desarrollador lo confirma en el simulador.

- [ ] **Step 6: Guardar la evidencia**

Crear `evidence/widget-tree-closed.txt` con la cabecera (herramienta `widget_inspector get_widget_tree summaryOnly`, iPhone Duo cerrado en vertical, fecha), el árbol resumido hasta `PageView` y la observación de la prueba de estado (título cambiado, contador y disco intactos).

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/cover_carousel.dart lib/screens/catalog_screen.dart evidence/widget-tree-closed.txt
git commit -m "feat: carrusel de portadas a pantalla completa"
```

### Task 8: Panel del disco y riel

**Files:**
- Create: `lib/widgets/album_hero_pane.dart`
- Create: `lib/widgets/album_rail.dart`

Estos widgets no se ven hasta la Task 9; aquí solo se analizan.

- [ ] **Step 1: Panel del disco**

`lib/widgets/album_hero_pane.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/album.dart';
import '../theme/app_theme.dart';
import 'generated_cover.dart';

/// Panel izquierdo del modo de dos paneles: portada en arco con un CD
/// asomando por detrás, título y datos básicos.
class AlbumHeroPane extends StatelessWidget {
  const AlbumHeroPane({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (album.year != null) '${album.year}',
      ?album.country,
      ?album.label,
    ].join(' · ');
    return ClipRect(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      const FractionalTranslation(
                        translation: Offset(0.3, 0.12),
                        child: _Disc(),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(999),
                        ),
                        child: GeneratedCover(album: album),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                album.title,
                textAlign: TextAlign.center,
                style: displayTitleStyle(34),
              ),
              const SizedBox(height: 8),
              Text(
                album.artist,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFFDADADA),
                Color(0xFF8E8E8E),
                Color(0xFFF2F2F2),
                Color(0xFF9A9A9A),
                Color(0xFFDADADA),
              ],
            ),
          ),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.28,
              heightFactor: 0.28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Riel**

`lib/widgets/album_rail.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/album.dart';
import 'generated_cover.dart';

/// Riel vertical con una miniatura por disco.
class AlbumRail extends StatelessWidget {
  const AlbumRail({
    super.key,
    required this.albums,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double width = 72;

  final List<Album> albums;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < albums.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  key: Key('rail-$i'),
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == selectedIndex ? 52 : 40,
                    height: i == selectedIndex ? 52 : 40,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == selectedIndex
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: GeneratedCover(album: albums[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analizar**

MCP `analyze_files` → Expected: `No errors`.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/album_hero_pane.dart lib/widgets/album_rail.dart
git commit -m "feat: panel del disco y riel de miniaturas"
```

---

## Parte C — Layout adaptativo y poses

### Task 9: Hacer responsiva la pantalla **[skill: flutter-build-responsive-layout]**

**Files:**
- Modify: `lib/screens/catalog_screen.dart`

En esta tarea el plan **no** dicta el código: lo escribe el skill. Es la regla del demo.

- [ ] **Step 1: Invocar el skill**

Invocar `flutter-build-responsive-layout` con este prompt, sin añadir cómo resolverlo:

```
Haz responsiva la pantalla de catálogo (lib/screens/catalog_screen.dart): cuando
el espacio es angosto muestra el carrusel de portadas (CoverCarousel); cuando es
amplio muestra, lado a lado, el riel de discos (AlbumRail), el panel del disco
(AlbumHeroPane) y el panel de detalle (AlbumDetailPane) del disco seleccionado.
```

- [ ] **Step 2: Comprobar el resultado contra lo que exige el skill**

- `LayoutBuilder` con `constraints.maxWidth`; nada de `MediaQuery.of(context).size` ni de orientación.
- Un breakpoint con nombre (el valor por defecto del skill es `600.0`). Anotar el valor y el operador de comparación: la Task 11 los reutiliza.
- Ninguna comprobación de tipo de dispositivo.
- `AlbumRail` recibe `selectedIndex: selection.index` y `onSelected: selection.select`; los dos paneles reciben `albums[selection.index]`.

Si falta algo, se le vuelve a pedir al skill; no se corrige a mano.

- [ ] **Step 3: Analizar y recargar**

MCP `analyze_files` → Expected: `No errors`.
MCP `hot_reload` con `clearRuntimeErrors: true`.
MCP `widget_inspector` `get_widget_tree` `summaryOnly: true`.
Expected (Duo cerrado): `LayoutBuilder → CoverCarousel`; el contador sigue en `2` y el disco sigue siendo *Disko 0*.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/catalog_screen.dart
git commit -m "feat: catálogo responsivo vía skill flutter-build-responsive-layout"
```

### Task 10: Medir cada pose por MCP

**Files:**
- Create: `evidence/widget-tree-open.txt`
- Modify: `evidence/widget-tree-closed.txt`

Para leer las constraints del `LayoutBuilder`: tomar su `valueId` del árbol resumido y llamar a MCP `vm_service` `callMethod` con `method: ext.flutter.inspector.getLayoutExplorerNode`, el `isolateId` de `getVM` y `arguments: {"id": "<valueId>", "groupName": "duo", "subtreeDepth": "1"}`. El campo `constraints` trae `maxWidth` y `maxHeight`, y `children` trae el widget construido.

- [ ] **Step 1: ⏸ [usuario] Duo cerrado, vertical** → medir. Expected: `maxWidth` < breakpoint, hijo `CoverCarousel`. Añadir la medida a `evidence/widget-tree-closed.txt`.

- [ ] **Step 2: ⏸ [usuario] Duo abierto, vertical** → medir. Expected: `maxWidth` ≈ 669, hijo con `AlbumRail`, `AlbumHeroPane` y `AlbumDetailPane`; el disco sigue siendo *Disko 0* y el contador `2`.

- [ ] **Step 3: ⏸ [usuario] Duo abierto, horizontal** → medir. Anotar `maxWidth` × `maxHeight`.

- [ ] **Step 4: ⏸ [usuario] Duo cerrado, horizontal** → medir. Expected: `maxWidth` ≈ 678 → dos paneles (decisión registrada en el spec).

- [ ] **Step 5: Errores de runtime en cada pose**

Tras cada medida, MCP `get_runtime_errors`. Si aparece un overflow o un error de constraints, **no** se corrige aquí: se anota la pose y el texto del error para la Task 12.

- [ ] **Step 6: Guardar evidencia y actualizar el spec**

Crear `evidence/widget-tree-open.txt` (vertical y horizontal, con cabecera, `maxWidth` por pose y árbol resumido). En `docs/superpowers/specs/2026-10-02-cd-catalog-duo-design.md`, reemplazar los dos "pendiente de medir" de la tabla de medidas por los valores obtenidos.

- [ ] **Step 7: Commit**

```bash
git add evidence docs/superpowers/specs/2026-10-02-cd-catalog-duo-design.md
git commit -m "docs: medidas del LayoutBuilder por pose vía MCP"
```

### Task 11: Postura y pliegue **[skill: dart-add-unit-test]**

**Files:**
- Create: `lib/layout/layout_mode.dart`
- Create: `lib/widgets/pose_badge.dart`
- Modify: `lib/screens/catalog_screen.dart`
- Test: `test/layout/layout_mode_test.dart`

Si en la Task 9 el skill eligió un breakpoint distinto de `600.0` o un operador distinto de `>`, usar aquí los del skill (en la constante, en `layoutFor` y en los valores límite del test) y reportarlo.

- [ ] **Step 1: Escribir el test que falla, invocando el skill**

Invocar `dart-add-unit-test` para `layoutFor` en `test/layout/layout_mode_test.dart`:

```dart
import 'package:duo_adaptive_demo/layout/layout_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layoutFor', () {
    test('ancho angosto con el teléfono cerrado es compacto', () {
      final layout = layoutFor(width: 466, posture: FoldPosture.closed);
      expect(layout.mode, LayoutMode.compact);
    });

    test('el breakpoint exacto sigue siendo compacto', () {
      final layout = layoutFor(
        width: largeScreenMinWidth,
        posture: FoldPosture.fullyOpen,
      );
      expect(layout.mode, LayoutMode.compact);
    });

    test('justo por encima del breakpoint son dos paneles', () {
      final layout = layoutFor(
        width: largeScreenMinWidth + 0.5,
        posture: FoldPosture.fullyOpen,
      );
      expect(layout.mode, LayoutMode.dualPane);
    });

    test('abierto del todo divide al 50 % y sin hueco', () {
      final layout = layoutFor(width: 669, posture: FoldPosture.fullyOpen);
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 334.5));
    });

    test('abierto del todo ignora la región del pliegue', () {
      final layout = layoutFor(
        width: 890,
        posture: FoldPosture.fullyOpen,
        foldLeft: 425,
        foldRight: 465,
      );
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 445));
    });

    test('plegado parcial separa los paneles en el pliegue', () {
      final layout = layoutFor(
        width: 890,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 425,
        foldRight: 465,
      );
      expect(
        layout,
        const CatalogLayout.dualPane(leftPaneWidth: 425, gapWidth: 40),
      );
    });

    test('plegado parcial sin región todavía divide al 50 %', () {
      final layout = layoutFor(width: 890, posture: FoldPosture.partiallyOpen);
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 445));
    });

    test('un pliegue fuera del ancho disponible se ignora', () {
      final layout = layoutFor(
        width: 669,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 660,
        foldRight: 700,
      );
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 334.5));
    });

    test('cerrado pero ancho (externa en horizontal) son dos paneles', () {
      final layout = layoutFor(width: 678, posture: FoldPosture.closed);
      expect(layout, const CatalogLayout.dualPane(leftPaneWidth: 339));
    });

    test('compacto aunque la postura sea parcial', () {
      final layout = layoutFor(
        width: 466,
        posture: FoldPosture.partiallyOpen,
        foldLeft: 200,
        foldRight: 240,
      );
      expect(layout, const CatalogLayout.compact());
    });
  });
}
```

- [ ] **Step 2: Correr el test y ver que falla**

MCP `run_tests` sobre `test/layout/layout_mode_test.dart`.
Expected: FALLA de compilación — `lib/layout/layout_mode.dart` no existe.

- [ ] **Step 3: Implementar la función pura**

`lib/layout/layout_mode.dart`:

```dart
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
```

- [ ] **Step 4: Correr el test y ver que pasa**

MCP `run_tests` sobre `test/layout/layout_mode_test.dart`.
Expected: 10 tests, todos PASS.

- [ ] **Step 5: Insignia de pose**

`lib/widgets/pose_badge.dart`:

```dart
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
```

- [ ] **Step 6: Integrar en la pantalla**

En `lib/screens/catalog_screen.dart`:

1. Borrar la constante de breakpoint que dejó el skill e importar la de `layout_mode.dart` (mismo valor).
2. Añadir los imports:

```dart
import 'package:foldable/foldable.dart';

import '../layout/layout_mode.dart';
import '../widgets/pose_badge.dart';
```

3. Añadir al final del archivo los dos adaptadores entre `foldable` y la función pura:

```dart
FoldPosture _postureOf(HingeStatus status) => switch (status) {
      HingeStatus.closed => FoldPosture.closed,
      HingeStatus.partiallyOpen => FoldPosture.partiallyOpen,
      HingeStatus.fullyOpen => FoldPosture.fullyOpen,
      HingeStatus.unknown => FoldPosture.unknown,
    };

/// El pliegue como franja vertical, o null si no hay región de división o
/// viene en horizontal.
Rect? _verticalFold(List<ReservedRegion> regions) {
  for (final region in regions) {
    if (region.kind == ReservedRegionKind.division &&
        region.bounds.height > region.bounds.width) {
      return region.bounds;
    }
  }
  return null;
}
```

4. Sustituir el `builder` del `LayoutBuilder` que dejó el skill por este, y la rama de dos paneles por `_buildDualPane`. La rama compacta (`CoverCarousel`) se deja como la escribió el skill.

```dart
          body: LayoutBuilder(
            builder: (context, constraints) {
              final posture = _postureOf(DuoMediaQuery.statusOf(context));
              final fold = _verticalFold(DuoMediaQuery.regionsOf(context));
              final layout = layoutFor(
                width: constraints.maxWidth,
                posture: posture,
                foldLeft: fold?.left,
                foldRight: fold?.right,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  switch (layout.mode) {
                    LayoutMode.compact =>
                      CoverCarousel(albums: albums, selection: selection),
                    LayoutMode.dualPane => _buildDualPane(layout),
                  },
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: PoseBadge(
                      posture: posture,
                      width: constraints.maxWidth,
                      layout: layout,
                    ),
                  ),
                ],
              );
            },
          ),
```

```dart
  Widget _buildDualPane(CatalogLayout layout) {
    final album = albums[selection.index];
    return Row(
      children: [
        SizedBox(
          width: layout.leftPaneWidth,
          child: Row(
            children: [
              AlbumRail(
                albums: albums,
                selectedIndex: selection.index,
                onSelected: selection.select,
              ),
              Expanded(child: AlbumHeroPane(album: album)),
            ],
          ),
        ),
        SizedBox(width: layout.gapWidth),
        Expanded(child: AlbumDetailPane(album: album)),
      ],
    );
  }
```

- [ ] **Step 7: Analizar y recargar**

MCP `analyze_files` → Expected: `No errors`.
MCP `hot_reload` con `clearRuntimeErrors: true`.
MCP `widget_inspector` `get_widget_tree` `summaryOnly: true`.
Expected: aparece un `Text` cuyo `textPreview` tiene la forma `<postura> · <ancho> pt · <modo>`; el contador sigue en `2`.

- [ ] **Step 8: Commit**

```bash
git add lib/layout lib/widgets/pose_badge.dart lib/screens/catalog_screen.dart test/layout
git commit -m "feat: los paneles se separan en el pliegue con el Duo plegado a medias"
```

### Task 12: Recorrido de poses y corrección de layout **[skill: flutter-fix-layout-issues]**

**Files:**
- Create: `evidence/widget-tree-partial.txt`, `evidence/runtime-errors-before.txt`, `evidence/runtime-errors-after.txt`
- Modify: los archivos que indique el skill

- [ ] **Step 1: Limpiar errores**

MCP `get_runtime_errors` con `clearRuntimeErrors: true`.

- [ ] **Step 2: ⏸ [usuario] Recorrer las poses**

En este orden, avisando en cada una: cerrado vertical → abierto vertical → **plegado parcial** → abierto horizontal → plegado parcial en horizontal → cerrado horizontal → cerrado vertical.

En cada pose el agente hace:
1. MCP `widget_inspector` `get_widget_tree` `summaryOnly: true` y lee el texto de `pose-badge`.
2. MCP `get_runtime_errors` (sin limpiar).

- [ ] **Step 3: Comprobar el plegado parcial**

Expected en `pose-badge`: `partiallyOpen · <ancho> pt · dualPane · pliegue <l>–<r>`.

Dos desviaciones posibles; ninguna se resuelve improvisando:
- **No aparece `pliegue`** con postura `partiallyOpen`: las regiones no llegaron o el pliegue viene en horizontal. Esperar ~1 s y releer. Si sigue sin aparecer, DETENERSE y reportar la postura, el ancho y la orientación.
- **Los paneles no coinciden con el pliegue en pantalla** (lo confirma el desarrollador a la vista): las coordenadas de la región no coinciden con las del `LayoutBuilder`. DETENERSE y reportar los valores `l`–`r` y el ancho.

- [ ] **Step 4: Guardar las lecturas "antes"**

Crear `evidence/runtime-errors-before.txt` con la cabecera y, por pose, el texto de `pose-badge` y la salida literal de `get_runtime_errors`. Crear `evidence/widget-tree-partial.txt` con el árbol resumido del plegado parcial.

- [ ] **Step 5: Corregir con el skill, si hay algo que corregir**

Si alguna pose reportó un overflow o un error de constraints, invocar `flutter-fix-layout-issues` pasándole el texto literal del error y la pose. El skill diagnostica con el árbol y aplica el fix; después:

MCP `hot_reload` con `clearRuntimeErrors: true`.
⏸ [usuario] Volver a la pose que fallaba.
MCP `get_runtime_errors` → Expected: sin errores.

Repetir por cada error distinto. Si **ninguna** pose reportó errores, no se invoca el skill y se deja escrito así en la evidencia: no se fabrica un bug.

- [ ] **Step 6: Guardar las lecturas "después"**

Crear `evidence/runtime-errors-after.txt` con la lectura final por pose y, si hubo fixes, qué cambió el skill y por qué.

- [ ] **Step 7: Confirmar la prueba de estado**

MCP `widget_inspector` `get_widget_tree` `summaryOnly: true`.
Expected: tras todo el recorrido, `favorites-count` sigue en `2` y el disco visible sigue siendo *Disko 0*.

- [ ] **Step 8: ⏸ [usuario] Capturas**

El desarrollador guarda una captura por pose en `evidence/` (`pose-closed.png`, `pose-open-portrait.png`, `pose-open-landscape.png`, `pose-partial.png`). El agente no puede sacarlas.

- [ ] **Step 9: Commit**

```bash
git add lib evidence
git commit -m "fix: layout verificado en todas las poses del Duo vía MCP"
```

---

## Parte D — Tests

### Task 13: Widget test **[skill: flutter-add-widget-test]**

**Files:**
- Test: `test/screens/catalog_screen_test.dart`

- [ ] **Step 1: Escribir el test invocando el skill**

Invocar `flutter-add-widget-test` para `CatalogScreen` con estos casos:

```dart
import 'package:duo_adaptive_demo/models/album.dart';
import 'package:duo_adaptive_demo/screens/catalog_screen.dart';
import 'package:duo_adaptive_demo/state/selection.dart';
import 'package:duo_adaptive_demo/widgets/album_detail_pane.dart';
import 'package:duo_adaptive_demo/widgets/album_hero_pane.dart';
import 'package:duo_adaptive_demo/widgets/album_rail.dart';
import 'package:duo_adaptive_demo/widgets/cover_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _albums = [
  Album(
    id: 4214311,
    title: 'Gorillaz',
    artist: 'Gorillaz',
    year: 2001,
    tracks: [Track(position: '1', title: 'Re-Hash', duration: '3:40')],
  ),
  Album(
    id: 9100081,
    title: 'Disko 0',
    artist: 'Sal Y Mileto',
    year: 2001,
    tracks: [Track(position: '1', title: 'Avisos Klasificados')],
  ),
];

Future<Selection> _pumpCatalog(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final selection = Selection();
  addTearDown(selection.dispose);
  await tester.pumpWidget(
    MaterialApp(home: CatalogScreen(albums: _albums, selection: selection)),
  );
  return selection;
}

void main() {
  testWidgets('a 466 pt de ancho muestra el carrusel', (tester) async {
    await _pumpCatalog(tester, const Size(466, 900));

    expect(find.byType(CoverCarousel), findsOneWidget);
    expect(find.byType(AlbumRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 890 pt de ancho muestra dos paneles sin overflow', (
    tester,
  ) async {
    await _pumpCatalog(tester, const Size(890, 669));

    expect(find.byType(CoverCarousel), findsNothing);
    expect(find.byType(AlbumRail), findsOneWidget);
    expect(find.byType(AlbumHeroPane), findsOneWidget);
    expect(find.byType(AlbumDetailPane), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 669 pt de ancho (interna en vertical) no hay overflow', (
    tester,
  ) async {
    await _pumpCatalog(tester, const Size(669, 951));

    expect(find.byType(AlbumRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el favorito sube el contador', (tester) async {
    await _pumpCatalog(tester, const Size(466, 900));

    await tester.tap(find.byKey(const Key('favorite-toggle')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('favorites-count'))).data,
      '1',
    );
  });

  testWidgets('el disco seleccionado se conserva al ensanchar', (tester) async {
    final selection = await _pumpCatalog(tester, const Size(466, 900));
    selection.select(1);
    await tester.pump();

    tester.view.physicalSize = const Size(890, 669);
    await tester.pump();

    expect(selection.index, 1);
    expect(
      find.descendant(
        of: find.byType(AlbumHeroPane),
        matching: find.text('Disko 0'),
      ),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Correr el test**

MCP `run_tests` sobre `test/screens/catalog_screen_test.dart`.
Expected: 5 tests, todos PASS. Si alguno falla por overflow, es un hallazgo real: volver a la Task 12, Step 5, con el texto del error.

- [ ] **Step 3: Commit**

```bash
git add test/screens/catalog_screen_test.dart
git commit -m "test: widget test del cambio entre carrusel y dos paneles"
```

### Task 14: Integration test **[skill: flutter-add-integration-test]**

**Files:**
- Create: `lib/main_test.dart`, `integration_test/app_test.dart` (los crea el skill)
- Modify: `pubspec.yaml` (dev-dependencies que añada el skill)

Esta tarea reinicia la app con otro entrypoint, así que la prueba de estado termina aquí. Hacerla después de las capturas de la Task 12.

- [ ] **Step 1: Invocar el skill**

Invocar `flutter-add-integration-test` para cubrir el flujo: abrir el catálogo → marcar el disco actual como favorito → el contador pasa a 1. Las `Key` ya existen: `favorite-toggle`, `favorites-count`, `open-details`, `rail-<i>`, `pose-badge`.

El skill crea `lib/main_test.dart` con `enableFlutterDriverExtension()` y añade las dependencias.

- [ ] **Step 2: ⏸ [usuario] Relanzar con el entrypoint de test**

El desarrollador detiene `flutter run` (`q`) y lo relanza:

```bash
fvm flutter run -t lib/main_test.dart -d 8A082039-2934-44E1-B92C-CDCE41CBC5C1
```

- [ ] **Step 3: Explorar el flujo con `flutter_driver_command`**

MCP `dtd` `listDtdUris` → `connect`.
MCP `flutter_driver_command` `command: get_health` → Expected: `ok`.
MCP `flutter_driver_command` `command: get_text`, `finderType: ByValueKey`, `keyValueString: favorites-count`, `keyValueType: String` → Expected: `0`.
MCP `flutter_driver_command` `command: tap`, mismo finder con `keyValueString: favorite-toggle`.
MCP `flutter_driver_command` `command: get_text` sobre `favorites-count` → Expected: `1`.

- [ ] **Step 4: El skill convierte el flujo en un test permanente**

Resultado esperado en `integration_test/app_test.dart`:

```dart
import 'package:duo_adaptive_demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Limitación: el test no puede cambiar la pose del Duo (no hay API de simctl
// ni de XCTest). Corre en la pose en la que esté el simulador.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('marcar un favorito sube el contador', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final count = find.byKey(const Key('favorites-count'));
    expect(tester.widget<Text>(count).data, '0');

    await tester.tap(find.byKey(const Key('favorite-toggle')));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(count).data, '1');
  });
}
```

- [ ] **Step 5: Analizar y commit**

MCP `analyze_files` → Expected: `No errors`.

```bash
git add lib/main_test.dart integration_test pubspec.yaml pubspec.lock
git commit -m "test: integration test del flujo de favoritos"
```

### Task 15: Ejecutar todos los tests por MCP

**Files:**
- Create: `evidence/tests.txt`

- [ ] **Step 1: Unit y widget tests**

MCP `run_tests` con `roots: [{root: <raíz>, paths: ["test"]}]`.
Expected: 33 tests (14 + 4 + 10 + 5), todos PASS.

- [ ] **Step 2: Integration test**

⏸ [usuario] Detener `flutter run` (`q`).
MCP `run_tests` con `paths: ["integration_test/app_test.dart"]`.
Si `run_tests` no puede dirigir el test al simulador, correr el fallback y dejarlo dicho como fallback en la evidencia:

```bash
fvm flutter test integration_test/app_test.dart -d 8A082039-2934-44E1-B92C-CDCE41CBC5C1
```

Expected: 1 test PASS.

- [ ] **Step 3: Guardar la evidencia y commit**

Crear `evidence/tests.txt` con cabecera (herramienta, dispositivo + pose, fecha), la salida de cada ejecución y, si aplicó, la nota del fallback.

```bash
git add evidence/tests.txt
git commit -m "docs: resultado de los tests ejecutados por MCP"
```

---

## Parte E — Documentación

### Task 16: SPEC y README

**Files:**
- Modify: `SPEC-iphone-duo-demo.md`
- Modify: `README.md` (reemplazo completo)

- [ ] **Step 1: Actualizar el SPEC**

En `SPEC-iphone-duo-demo.md`:

1. Sección "Lo que se reusa del demo de Agent Skills": reemplazar las tres viñetas por un párrafo que diga que de ese demo se reusa el método (prompt que no dicta la solución, `skills-lock`/hashes, formato de `evidence/`), no el código: el catálogo de productos se sustituyó por el catálogo de CDs descrito en `docs/superpowers/specs/2026-10-02-cd-catalog-duo-design.md`.
2. Fase 1, viñeta "Copiar del repo `agent-skills-flutter-demo`": reemplazarla por la estructura de `lib/` del documento de diseño y el baseline de lista plana de CDs.
3. Fase 1: quitar la mención a `ios/Podfile` (Flutter 3.47 usa Swift Package Manager; el target 15.0 está en el proyecto Xcode).
4. Fase 2.1: `.agents/skills/` y `skills-lock.json` pasan a `.claude/skills/` y `.config/dart_skills/skills_config.json`; el comando real es `fvm dart run skills@ add flutter/agent-plugins --all --agent claude`.
5. Fase 2.2: el `.mcp.json` lleva `--enable run_tests` (deshabilitado por defecto en `dart_mcp_server` 1.1.2).
6. Fase 4.3: quitar la expectativa del overflow de 7.7 px.
7. Tabla "Estado del entorno": actualizar a lo instalado (Flutter 3.47.4 / Dart 3.13.3, Xcode 27.1 en `/Applications/Xcode-beta.app`, runtime iOS 27.1, iPhone Duo).

- [ ] **Step 2: Escribir el README**

`README.md` con la misma estructura que los dos repos anteriores, usando solo datos que consten en `evidence/` y en el historial de git:

- **TL;DR:** qué es el demo y qué muestra.
- **Requisitos:** versiones de la tabla de entorno del SPEC.
- **La app:** los 5 discos, de dónde salen los datos (Discogs, CC0), por qué las portadas son generadas.
- **Cómo se usó cada tool:** una subsección por tool (Agent Skills, Dart & Flutter MCP server, Agentic Hot Reload) con el commit y el archivo de evidencia de cada uso.
- **Medidas por pose:** la tabla del documento de diseño.
- **Limitaciones:** las poses solo se cambian a mano; el integration test corre en la pose en que esté el simulador; `run_tests` hay que habilitarlo; `open -a Simulator` abre el simulador de Xcode 26.5.
- **Reproducirlo:** `fvm install`, `fvm flutter pub get`, lanzar DeviceHub, `fvm flutter run -d <udid>`.
- **Créditos de datos:** enlace a `assets/discogs/ATTRIBUTION.md`.

- [ ] **Step 3: Commit**

```bash
git add SPEC-iphone-duo-demo.md README.md
git commit -m "docs: README y SPEC actualizados al catálogo de CDs"
```

- [ ] **Step 4: ⏸ Resumen final**

Reportar al desarrollador: qué se construyó, qué tool o skill se usó en cada tarea (con commit), qué evidencia quedó en `evidence/` y el checklist de las 3 tools del SPEC. **No** crear remoto ni publicar el repo sin confirmación explícita.
