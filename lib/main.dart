import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stock_pilot/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initDesktopDatabase();
  runApp(const StockPilotApp());
}

/// Swap the sqflite database factory for FFI on desktop platforms.
void _initDesktopDatabase() {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
