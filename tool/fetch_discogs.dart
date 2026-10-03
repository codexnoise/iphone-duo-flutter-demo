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
