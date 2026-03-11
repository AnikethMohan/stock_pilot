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
      onUpgrade: _onUpgrade,
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
        cost_price          REAL    NOT NULL DEFAULT 0.0,
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

    // ── V2 tables ──────────────────────────────────────────────────
    await _createV2Tables(db);

    // ── V3 tables ──────────────────────────────────────────────────
    await _createV3Tables(db);

    // ── V4 tables ──────────────────────────────────────────────────
    await _createV4Tables(db);

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

  /// Upgrade handler — additive-only, never drops tables.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add cost_price column to existing products table.
      await db.execute(
        'ALTER TABLE products ADD COLUMN cost_price REAL NOT NULL DEFAULT 0.0',
      );
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
      await _migrateV2ToV3(db);
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
      await _migrateV3ToV4(db);
    }
  }

  /// V2 schema: customers, invoices, invoice_items.
  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        phone      TEXT,
        email      TEXT,
        address    TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT    NOT NULL UNIQUE,
        customer_id    INTEGER,
        subtotal       REAL    NOT NULL DEFAULT 0.0,
        tax_percent    REAL    NOT NULL DEFAULT 0.0,
        tax_amount     REAL    NOT NULL DEFAULT 0.0,
        grand_total    REAL    NOT NULL DEFAULT 0.0,
        status         TEXT    NOT NULL DEFAULT 'draft',
        notes          TEXT,
        created_at     TEXT    NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id   INTEGER NOT NULL,
        product_id   INTEGER NOT NULL,
        sku          TEXT    NOT NULL,
        product_name TEXT    NOT NULL,
        unit_price   REAL    NOT NULL,
        quantity     REAL    NOT NULL,
        line_total   REAL    NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
  }

  /// V3 schema: unified sales_documents and sales_document_items.
  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_documents (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        doc_type          TEXT    NOT NULL,
        doc_number        TEXT    NOT NULL UNIQUE,
        customer_id       INTEGER,
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
        FOREIGN KEY (source_doc_id) REFERENCES sales_documents(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_document_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id      INTEGER NOT NULL,
        product_id       INTEGER NOT NULL,
        sku              TEXT    NOT NULL,
        product_name     TEXT    NOT NULL,
        unit_price       REAL    NOT NULL,
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
  }

  /// Migrate existing invoices from V2 tables into V3 sales_documents tables.
  Future<void> _migrateV2ToV3(Database db) async {
    final invoices = await db.query('invoices');
    for (final inv in invoices) {
      final oldId = inv['id'] as int;
      final newId = await db.insert('sales_documents', {
        'doc_type': 'invoice',
        'doc_number': inv['invoice_number'],
        'customer_id': inv['customer_id'],
        'subtotal': inv['subtotal'],
        'discount_percent': 0.0,
        'discount_amount': 0.0,
        'tax_amount': inv['tax_amount'],
        'grand_total': inv['grand_total'],
        'status': inv['status'],
        'notes': inv['notes'],
        'created_at': inv['created_at'],
      });

      final items = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [oldId],
      );
      for (final item in items) {
        await db.insert('sales_document_items', {
          'document_id': newId,
          'product_id': item['product_id'],
          'sku': item['sku'],
          'product_name': item['product_name'],
          'unit_price': item['unit_price'],
          'quantity': item['quantity'],
          'discount_percent': 0.0,
          'discount_amount': 0.0,
          'tax_percent': 0.0,
          'tax_amount': 0.0,
          'line_total': item['line_total'],
        });
      }
    }
  }

  /// V4 schema: suppliers, add supplier_id to sales_documents.
  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        phone      TEXT,
        email      TEXT,
        address    TEXT,
        created_at TEXT    NOT NULL
      )
    ''');
  }

  /// Migrate existing V3 sales_documents to include supplier_id.
  Future<void> _migrateV3ToV4(Database db) async {
    await db.execute(
      'ALTER TABLE sales_documents ADD COLUMN supplier_id INTEGER REFERENCES suppliers(id)',
    );
  }
}
