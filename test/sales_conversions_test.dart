import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/database/database_helper.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/features/sales/data/datasources/sales_local_datasource.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late Database db;
  late MockDatabaseHelper mockDbHelper;
  late SalesLocalDataSource dataSource;

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
        item_name            TEXT    NOT NULL,
        quantity_on_hand     REAL    NOT NULL DEFAULT 0.0,
        sales_rate           REAL    NOT NULL DEFAULT 0.0,
        created_at           TEXT    NOT NULL,
        updated_at           TEXT    NOT NULL
      )
    ''');

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
        return_reason     TEXT,
        return_to_stock   INTEGER NOT NULL DEFAULT 0,
        generate_credit_note INTEGER NOT NULL DEFAULT 0,
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
        disposition      TEXT,
        return_condition TEXT,
        FOREIGN KEY (document_id) REFERENCES sales_documents(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id)  REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

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

    mockDbHelper = MockDatabaseHelper();
    when(() => mockDbHelper.database).thenAnswer((_) async => db);
    dataSource = SalesLocalDataSource(dbHelper: mockDbHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('Sales Conversions Constraints', () {
    test('Should REJECT creating multiple invoices from same DN', () async {
      // 1. Create a Delivery Note
      final dn = SalesDocument(
        docType: DocType.deliveryNote,
        docNumber: 'DN-00001',
        createdAt: DateTime.now(),
      );
      final savedDn = await dataSource.saveDocument(dn);

      // 2. Convert to Invoice 1 (Success)
      await dataSource.convertDocument(savedDn.id!, DocType.invoice);

      // 3. Convert to Invoice 2 (Should Fail)
      expect(
        () => dataSource.convertDocument(savedDn.id!, DocType.invoice),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Should REJECT creating delivery return when invoice already exists', () async {
      // 1. Create a Delivery Note
      final dn = SalesDocument(
        docType: DocType.deliveryNote,
        docNumber: 'DN-00001',
        createdAt: DateTime.now(),
      );
      final savedDn = await dataSource.saveDocument(dn);

      // 2. Convert to Invoice
      await dataSource.convertDocument(savedDn.id!, DocType.invoice);

      // 3. Convert to Delivery Return (Should Fail)
      expect(
        () => dataSource.convertDocument(savedDn.id!, DocType.deliveryReturn),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('confirmDocument should REJECT if another invoice exists', () async {
       // 1. Create DN
       final dn = SalesDocument(
        docType: DocType.deliveryNote,
        docNumber: 'DN-00001',
        createdAt: DateTime.now(),
      );
      final savedDn = await dataSource.saveDocument(dn);

      // 2. Create Invoice 1 and confirm it
      final inv1 = await dataSource.convertDocument(savedDn.id!, DocType.invoice);
      await dataSource.confirmDocument(inv1);

      // 3. Manually create Invoice 2 (simulating a bypass of convertDocument check)
      final inv2 = SalesDocument(
        docType: DocType.invoice,
        docNumber: 'INV-00002',
        sourceDocId: savedDn.id,
        createdAt: DateTime.now(),
        items: const [], // empty for simplicity, but confirmDocument needs items?
      );
      // confirmDocument checks for empty items... let's add an item
      final inv2WithItem = inv2.copyWith(items: [
        const SalesDocItem(
          productId: 1, 
          itemCode: 'ITEM-1', 
          productName: 'Item 1', 
          salesRate: 10, 
          quantity: 1,
          lineTotal: 10,
        ),
      ]);
      // We need the product in DB
      await db.insert('products', {
        'id': 1,
        'item_code': 'ITEM-1',
        'item_name': 'Item 1',
        'quantity_on_hand': 10.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Confirming inv2 should fail because inv1 is already confirmed for this DN
      expect(
        () => dataSource.confirmDocument(inv2WithItem),
        throwsA(predicate((e) => e is ValidationFailure && e.message.contains('Another invoice already exists'))),
      );
    });

    test('confirmDocument should REJECT delivery return if invoice exists', () async {
       // 1. Create DN
       final dn = SalesDocument(
        docType: DocType.deliveryNote,
        docNumber: 'DN-00001',
        createdAt: DateTime.now(),
      );
      final savedDn = await dataSource.saveDocument(dn);

      // 2. Create and confirm Invoice
      final inv = await dataSource.convertDocument(savedDn.id!, DocType.invoice);
      await dataSource.confirmDocument(inv);

      // 3. Create Delivery Return
      final rtn = SalesDocument(
        docType: DocType.deliveryReturn,
        docNumber: 'RTN-00001',
        sourceDocId: savedDn.id,
        createdAt: DateTime.now(),
        items: [
          const SalesDocItem(
            productId: 1, 
            itemCode: 'ITEM-1', 
            productName: 'Item 1', 
            salesRate: 10, 
            quantity: 1,
            lineTotal: 10,
          ),
        ],
      );

      // Confirming return should fail
      expect(
        () => dataSource.confirmDocument(rtn),
        throwsA(predicate((e) => e is ValidationFailure && e.message.contains('Cannot confirm delivery return because an invoice already exists'))),
      );
    });
  });
}
