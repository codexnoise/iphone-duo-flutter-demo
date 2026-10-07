import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart';

/// Punto de entrada para explorar la app con Flutter Driver (MCP
/// `flutter_driver_command`): igual que `main.dart`, con la extensión de
/// Driver habilitada.
///
/// Uso: `fvm flutter run -t lib/main_test.dart -d <udid>`
void main() {
  enableFlutterDriverExtension();
  runApp(const DuoAdaptiveApp());
}
