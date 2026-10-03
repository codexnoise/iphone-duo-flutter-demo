import 'package:flutter/material.dart';

/// Marcador de estado: si este número sobrevive a un cambio de pose o a un
/// hot reload, la app no se reinició.
class FavoritesCounter extends StatefulWidget {
  const FavoritesCounter({super.key});

  @override
  State<FavoritesCounter> createState() => _FavoritesCounterState();
}

class _FavoritesCounterState extends State<FavoritesCounter> {
  int _favorites = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => setState(() => _favorites++),
      icon: const Icon(Icons.favorite),
      label: Text('$_favorites'),
    );
  }
}
