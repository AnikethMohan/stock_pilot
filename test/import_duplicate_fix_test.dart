import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stock_pilot/core/database/database_helper.dart';
import 'package:stock_pilot/features/inventory/data/repositories/stock_repository_impl.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late Database db;
  late MockDatabaseHelper mockDbHelper;
  late StockRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    
    // Create necessary tables
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
      CREATE TABLE inventory_imports (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        filename   TEXT    NOT NULL,
        date       TEXT    NOT NULL,
        total_rows INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id     INTEGER NOT NULL,
        quantity_delta REAL    NOT NULL,
        movement_type  TEXT    NOT NULL,
        reference_id   TEXT,
        timestamp      TEXT    NOT NULL,
        notes          TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    mockDbHelper = MockDatabaseHelper();
    when(() => mockDbHelper.database).thenAnswer((_) async => db);
    repository = StockRepositoryImpl(databaseHelper: mockDbHelper);
  });

  tearDown(() async {
    await db.close();
  });

  test('importCsvBulk handles duplicate item codes in CSV correctly (new products)', () async {
    const csvString =
        'item_code,item_name,quantity_on_hand\n'
        'DUP-01,Product 1,10\n'
        'DUP-01,Product 1,20\n';

    await repository.importCsvBulk('test.csv', csvString);

    // Verify DUP-01 exists and has quantity 30 (10 + 20)
    final products = await db.query('products', where: 'item_code = ?', whereArgs: ['DUP-01']);
    expect(products.length, 1);
    expect(products.first['quantity_on_hand'], 30.0);

    // Verify stock movements
    final movements = await db.query('stock_movements', where: 'product_id = ?', whereArgs: [products.first['id']]);
    expect(movements.length, 2);
    expect(movements[0]['quantity_delta'], 10.0);
    expect(movements[1]['quantity_delta'], 20.0);
  });

  test('importCsvBulk handles item codes with single quotes correctly', () async {
    const itemCode = "MTB-407-22''";
    
    // 1. First import
    const csvString1 =
        'item_code,item_name,quantity_on_hand\n'
        '"$itemCode",Product 1,10\n';

    await repository.importCsvBulk('test1.csv', csvString1);

    // Verify it exists
    final productsBefore = await db.query('products', where: 'item_code = ?', whereArgs: [itemCode]);
    expect(productsBefore.length, 1);
    expect(productsBefore.first['quantity_on_hand'], 10.0);

    // 2. Second import (with same item_code)
    const csvString2 =
        'item_code,item_name,quantity_on_hand\n'
        '"$itemCode",Product 1,20\n';

    await repository.importCsvBulk('test2.csv', csvString2);

    // Verify it was updated (10 + 20 = 30)
    final productsAfter = await db.query('products', where: 'item_code = ?', whereArgs: [itemCode]);
    expect(productsAfter.length, 1);
    expect(productsAfter.first['quantity_on_hand'], 30.0);
  });
}
