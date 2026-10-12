// Descarga la portada principal de cada release de Discogs a
// assets/covers/<id>.jpg para usarla en builds locales.
//
// Las portadas tienen copyright (no son CC0): la carpeta está en .gitignore y
// las imágenes no se versionan. Sin ellas la app usa la portada generada por
// código.
//
// Uso: fvm dart run tool/fetch_covers.dart
import 'dart:convert';
import 'dart:io';

const releaseIds = [4214311, 13115020, 9100081, 11066248, 8172924];
const userAgent = 'DuoCdDemo/0.1 +https://github.com/codexnoise';

Future<void> main() async {
  final client = HttpClient();
  final outDir = Directory('assets/covers')..createSync(recursive: true);
  for (final id in releaseIds) {
    final release = jsonDecode(
      await _get(client, Uri.parse('https://api.discogs.com/releases/$id')),
    ) as Map<String, dynamic>;
    final images = (release['images'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final primary = images.firstWhere(
      (image) => image['type'] == 'primary',
      orElse: () => images.isEmpty ? const {} : images.first,
    );
    final uri = primary['uri'] as String?;
    if (uri == null) {
      stderr.writeln('release $id: sin imagen');
      exitCode = 1;
      continue;
    }
    final request = await client.getUrl(Uri.parse(uri));
    request.headers.set(HttpHeaders.userAgentHeader, userAgent);
    final response = await request.close();
    final file = File('${outDir.path}/$id.jpg');
    await response.pipe(file.openWrite());
    stdout.writeln('release $id: ${file.lengthSync()} bytes');
    // Límite sin autenticación: 25 peticiones por minuto.
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  client.close();
}

Future<String> _get(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.headers.set(HttpHeaders.userAgentHeader, userAgent);
  final response = await request.close();
  return response.transform(utf8.decoder).join();
}
