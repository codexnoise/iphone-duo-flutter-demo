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
