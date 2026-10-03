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
