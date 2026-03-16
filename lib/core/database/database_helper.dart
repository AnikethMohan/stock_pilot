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

  /// Create all tables in their final state.
  Future<void> _onCreate(Database db, int version) async {
    // ─── Products ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE products (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code            TEXT    NOT NULL UNIQUE,
        barcode              TEXT,
        item_name            TEXT    NOT NULL,
        brand                TEXT,
        product_group        TEXT,
        description          TEXT,
        detailed_description TEXT,
        sales_rate           REAL    NOT NULL DEFAULT 0.0,
        cost_price           REAL    NOT NULL DEFAULT 0.0,
        purchase_rate        REAL    NOT NULL DEFAULT 0.0,
        wholesale_price      REAL    NOT NULL DEFAULT 0.0,
        mrp                  REAL    NOT NULL DEFAULT 0.0,
        profit_percentage    REAL    NOT NULL DEFAULT 0.0,
        minimum_sale_rate    REAL    NOT NULL DEFAULT 0.0,
        addin_part_number_1  TEXT,
        addin_part_number_2  TEXT,
        image                TEXT,
        other_language       TEXT,
        quantity_on_hand     REAL    NOT NULL DEFAULT 0.0,
        unit_of_measure      TEXT    NOT NULL DEFAULT 'Pieces',
        low_stock_threshold  REAL    NOT NULL DEFAULT 10.0,
        location_aisle       TEXT,
        location_shelf       TEXT,
        location_bin         TEXT,
        created_at           TEXT    NOT NULL,
        updated_at           TEXT    NOT NULL
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

    // ─── Transactions ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE transactions (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id      INTEGER NOT NULL,
        item_code       TEXT    NOT NULL,
        timestamp       TEXT    NOT NULL,
        change_amount   REAL    NOT NULL,
        reason          TEXT    NOT NULL,
        resulting_total REAL    NOT NULL,
        notes           TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // ─── Stakeholders ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE customers (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        phone      TEXT,
        email      TEXT,
        address    TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        phone      TEXT,
        email      TEXT,
        address    TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    // ─── Sales & Purchases ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE sales_documents (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        doc_type          TEXT    NOT NULL,
        doc_number        TEXT    NOT NULL UNIQUE,
        customer_id       INTEGER,
        supplier_id       INTEGER,
        subtotal          REAL    NOT NULL DEFAULT 0.0,
        discount_percent  REAL    NOT NULL DEFAULT 0.0,
        discount_amount   REAL    NOT NULL DEFAULT 0.0,
        tax_amount        REAL    NOT NULL DEFAULT 0.0,
        grand_total       REAL    NOT NULL DEFAULT 0.0,
        status            TEXT    NOT NULL DEFAULT 'draft',
        source_doc_id     INTEGER,
        source_doc_number TEXT,
        delivery_date     TEXT,
        payment_status    TEXT,
        notes             TEXT,
        created_at        TEXT    NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
        FOREIGN KEY (source_doc_id) REFERENCES sales_documents(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales_document_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id      INTEGER NOT NULL,
        product_id       INTEGER NOT NULL,
        item_code        TEXT    NOT NULL,
        product_name     TEXT    NOT NULL,
        sales_rate       REAL    NOT NULL,
        quantity         REAL    NOT NULL,
        discount_percent REAL    NOT NULL DEFAULT 0.0,
        discount_amount  REAL    NOT NULL DEFAULT 0.0,
        tax_percent      REAL    NOT NULL DEFAULT 0.0,
        tax_amount       REAL    NOT NULL DEFAULT 0.0,
        line_total       REAL    NOT NULL,
        FOREIGN KEY (document_id) REFERENCES sales_documents(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id)  REFERENCES products(id)
      )
    ''');

    // ─── Settings ──────────────────────────────────────────────────
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
