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
