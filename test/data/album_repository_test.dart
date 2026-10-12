import 'package:duo_adaptive_demo/data/album_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlbumRepository', () {
    test('carga los 5 discos en el orden del catálogo', () async {
      final albums = await const AlbumRepository().loadAll();
      expect(albums.map((album) => album.id), kReleaseIds);
    });

    test('usa el título para mostrar en lugar del de Discogs', () async {
      final albums = await const AlbumRepository().loadAll();
      final gondwana = albums.singleWhere((album) => album.id == 11066248);
      expect(gondwana.title, 'Alabanza');
      expect(gondwana.artist, 'Gondwana');
      expect(gondwana.tracks, hasLength(12));
    });
  });
}
