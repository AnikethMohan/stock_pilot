/// Local data source — raw SQLite operations for inventory, transactions, and settings.
library;

import 'package:sqflite/sqflite.dart';
import 'package:stock_pilot/core/database/database_helper.dart';
import 'package:stock_pilot/features/inventory/data/models/product_model.dart';
import 'package:stock_pilot/features/transactions/data/models/transaction_model.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

class InventoryLocalDataSource {
  InventoryLocalDataSource({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  // ─── Products ────────────────────────────────────────────────────

  /// Get products with optional filters, pagination via [limit] and [offset].
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add(
        '(name LIKE ? OR sku LIKE ? OR brand LIKE ? OR description LIKE ? OR more_description LIKE ?)',
      );
      final q = '%$searchQuery%';
      whereArgs.addAll([q, q, q, q, q]);
    }
    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (lowStockOnly == true) {
      whereClauses.add('quantity_on_hand <= low_stock_threshold');
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final rows = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    if (rows.isEmpty) return [];

    // Batch-load metadata for all product IDs in one query (fixes N+1).
    final productIds = rows.map((r) => r['id'] as int).toList();
    final metaMap = await _getMetadataForProducts(db, productIds);

    final products = <Product>[];
    for (final row in rows) {
      final id = row['id'] as int;
      products.add(ProductModel.fromMap(row, metadata: metaMap[id] ?? []));
    }
    return products;
  }

  /// Get total count of products matching the given filters (for pagination).
  Future<int> getProductCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(name LIKE ? OR sku LIKE ? OR brand LIKE ?)');
      final q = '%$searchQuery%';
      whereArgs.addAll([q, q, q]);
    }
    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (lowStockOnly == true) {
      whereClauses.add('quantity_on_hand <= low_stock_threshold');
    }

    final whereStr = whereClauses.isEmpty
        ? ''
        : 'WHERE ${whereClauses.join(' AND ')}';
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products $whereStr',
      whereArgs.isEmpty ? null : whereArgs,
    );
    return (result.first['cnt'] as num).toInt();
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final meta = await _getMetadataForProduct(db, id);
    return ProductModel.fromMap(rows.first, metadata: meta);
  }

  Future<Product?> getProductBySku(String sku) async {
    final db = await _dbHelper.database;
    final rows = await db.query('products', where: 'sku = ?', whereArgs: [sku]);
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as int;
    final meta = await _getMetadataForProduct(db, id);
    return ProductModel.fromMap(rows.first, metadata: meta);
  }

  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    final id = await db.insert('products', ProductModel.toMap(product));

    // Insert metadata
    for (final m in product.metadata) {
      await db.insert('product_metadata', MetadataModel.toMap(m, id));
    }
    return id;
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    final map = ProductModel.toMap(product);
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update('products', map, where: 'id = ?', whereArgs: [product.id]);

    // Replace metadata
    await db.delete(
      'product_metadata',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
    for (final m in product.metadata) {
      await db.insert('product_metadata', MetadataModel.toMap(m, product.id!));
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(int productId, double newQuantity) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'quantity_on_hand': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != '' ORDER BY category",
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Chunked upsert — splits products into batches of [chunkSize] and commits
  /// each batch separately so SQLite isn't locked for too long.
  /// Calls [onProgress] after each chunk with (processedSoFar, total).
  Future<int> upsertProductsChunked(
    List<Product> products, {
    int chunkSize = 500,
    void Function(int processed, int total)? onProgress,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    int processed = 0;

    for (var start = 0; start < products.length; start += chunkSize) {
      final end = (start + chunkSize > products.length)
          ? products.length
          : start + chunkSize;
      final chunk = products.sublist(start, end);

      final batch = db.batch();
      for (final p in chunk) {
        batch.rawInsert(
          '''
          INSERT INTO products (sku, name, brand, category, description,more_description,
                                unit_price, quantity_on_hand, unit_of_measure,
                                low_stock_threshold, location_aisle, location_shelf,
                                location_bin, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)
          ON CONFLICT(sku) DO UPDATE SET
            name             = COALESCE(excluded.name, products.name),
            brand            = COALESCE(excluded.brand, products.brand),
            category         = COALESCE(excluded.category, products.category),
            more_description = COALESCE(excluded.more_description, products.more_description),
            description      = COALESCE(excluded.description, products.description),
            unit_price       = COALESCE(excluded.unit_price, products.unit_price),
            quantity_on_hand = products.quantity_on_hand + excluded.quantity_on_hand,
            unit_of_measure  = COALESCE(excluded.unit_of_measure, products.unit_of_measure),
            updated_at       = ?
        ''',
          [
            p.sku,
            p.name,
            p.brand,
            p.category,
            p.moreDescription,
            p.description,
            p.unitPrice,
            p.quantityOnHand,
            p.unitOfMeasure.label,
            p.lowStockThreshold,
            p.locationAisle,
            p.locationShelf,
            p.locationBin,
            now,
            now,
            now,
          ],
        );
      }
      await batch.commit(noResult: true);

      // ── Persist metadata for products that have custom attributes ──
      final productsWithMeta = chunk
          .where((p) => p.metadata.isNotEmpty)
          .toList();
      if (productsWithMeta.isNotEmpty) {
        // Look up the product IDs by SKU for this chunk.
        final skus = productsWithMeta.map((p) => p.sku).toList();
        final placeholders = List.filled(skus.length, '?').join(',');
        final idRows = await db.rawQuery(
          'SELECT id, sku FROM products WHERE sku IN ($placeholders)',
          skus,
        );
        final skuToId = <String, int>{};
        for (final row in idRows) {
          skuToId[row['sku'] as String] = row['id'] as int;
        }

        final metaBatch = db.batch();
        for (final p in productsWithMeta) {
          final productId = skuToId[p.sku];
          if (productId == null) continue;
          for (final m in p.metadata) {
            metaBatch.rawInsert(
              '''
              INSERT OR REPLACE INTO product_metadata (product_id, key, value)
              VALUES (?, ?, ?)
              ''',
              [productId, m.key, m.value],
            );
          }
        }
        await metaBatch.commit(noResult: true);
      }

      processed += chunk.length;
      onProgress?.call(processed, products.length);
    }

    return products.length;
  }

  /// Legacy upsert — kept for backward compat but delegates to chunked.
  Future<int> upsertProducts(List<Product> products) {
    return upsertProductsChunked(products);
  }

  // ─── Aggregations ────────────────────────────────────────────────

  Future<double> getTotalInventoryValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(unit_price * quantity_on_hand), 0) as total FROM products',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getPotentialProfit() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM((unit_price - cost_price) * quantity_on_hand), 0) as profit FROM products',
    );
    return (result.first['profit'] as num).toDouble();
  }

  Future<int> getLowStockCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE quantity_on_hand <= low_stock_threshold',
    );
    return (result.first['cnt'] as num).toInt();
  }

  // ─── Transactions ────────────────────────────────────────────────

  Future<int> insertTransaction(StockTransaction txn) async {
    final db = await _dbHelper.database;
    return db.insert('transactions', TransactionModel.toMap(txn));
  }

  Future<List<StockTransaction>> getTransactions({
    int? productId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;
    if (productId != null) {
      where = 'product_id = ?';
      whereArgs = [productId];
    }
    final rows = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<StockTransaction>> getRecentTransactions({int limit = 10}) async {
    return getTransactions(limit: limit);
  }

  // ─── Settings ────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Internal ────────────────────────────────────────────────────

  Future<List<ProductMetadata>> _getMetadataForProduct(
    Database db,
    int productId,
  ) async {
    final rows = await db.query(
      'product_metadata',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return rows.map(MetadataModel.fromMap).toList();
  }

  /// Batch-load metadata for multiple product IDs, chunked to avoid
  /// SQLite's variable limit (~999 placeholders).
  Future<Map<int, List<ProductMetadata>>> _getMetadataForProducts(
    Database db,
    List<int> productIds,
  ) async {
    if (productIds.isEmpty) return {};

    const chunkSize = 500;
    final map = <int, List<ProductMetadata>>{};

    for (var start = 0; start < productIds.length; start += chunkSize) {
      final end = (start + chunkSize > productIds.length)
          ? productIds.length
          : start + chunkSize;
      final chunk = productIds.sublist(start, end);

      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT * FROM product_metadata WHERE product_id IN ($placeholders)',
        chunk,
      );

      for (final row in rows) {
        final pid = row['product_id'] as int;
        map.putIfAbsent(pid, () => []);
        map[pid]!.add(MetadataModel.fromMap(row));
      }
    }

    return map;
  }
}
