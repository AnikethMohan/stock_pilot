/// SQLite database helper — singleton that manages the app's local database.
library;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppDefaults.dbName);

    return openDatabase(
      path,
      version: AppDefaults.dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign-key support.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables on first launch.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        sku                 TEXT    NOT NULL UNIQUE,
        name                TEXT    NOT NULL,
        brand               TEXT,
        category            TEXT,
        description         TEXT,
        more_description    TEXT,
        unit_price          REAL    NOT NULL DEFAULT 0.0,
        quantity_on_hand    REAL    NOT NULL DEFAULT 0.0,
        unit_of_measure     TEXT    NOT NULL DEFAULT 'Pieces',
        low_stock_threshold REAL    NOT NULL DEFAULT 10.0,
        location_aisle      TEXT,
        location_shelf      TEXT,
        location_bin        TEXT,
        created_at          TEXT    NOT NULL,
        updated_at          TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_metadata (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id  INTEGER NOT NULL,
        key         TEXT    NOT NULL,
        value       TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE(product_id, key)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id      INTEGER NOT NULL,
        sku             TEXT    NOT NULL,
        timestamp       TEXT    NOT NULL,
        change_amount   REAL    NOT NULL,
        reason          TEXT    NOT NULL,
        resulting_total REAL    NOT NULL,
        notes           TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default settings
    await db.insert('settings', {
      'key': SettingsKeys.allowNegativeStock,
      'value': AppDefaults.defaultAllowNegativeStock.toString(),
    });
    await db.insert('settings', {
      'key': SettingsKeys.defaultLowStockThreshold,
      'value': AppDefaults.defaultLowStockThreshold.toString(),
    });
  }
}
