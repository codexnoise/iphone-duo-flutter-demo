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
