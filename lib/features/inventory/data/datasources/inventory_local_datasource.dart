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
    String? productGroup,
    bool? lowStockOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add(
        '(item_name LIKE ? OR item_code LIKE ? OR brand LIKE ? OR description LIKE ? OR detailed_description LIKE ?)',
      );
      final q = '%$searchQuery%';
      whereArgs.addAll([q, q, q, q, q]);
    }
    if (productGroup != null && productGroup.isNotEmpty) {
      whereClauses.add('product_group = ?');
      whereArgs.add(productGroup);
    }
    if (lowStockOnly == true) {
      whereClauses.add('quantity_on_hand <= low_stock_threshold');
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final rows = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'item_name ASC',
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
    String? productGroup,
    bool? lowStockOnly,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(item_name LIKE ? OR item_code LIKE ? OR brand LIKE ?)');
      final q = '%$searchQuery%';
      whereArgs.addAll([q, q, q]);
    }
    if (productGroup != null && productGroup.isNotEmpty) {
      whereClauses.add('product_group = ?');
      whereArgs.add(productGroup);
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

  Future<Product?> getProductByItemCode(String itemCode) async {
    final db = await _dbHelper.database;
    final rows = await db.query('products', where: 'item_code = ?', whereArgs: [itemCode]);
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

  Future<List<String>> getProductGroups() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT product_group FROM products WHERE product_group IS NOT NULL AND product_group != '' ORDER BY product_group",
    );
    return rows.map((r) => r['product_group'] as String).toList();
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
          INSERT INTO products (item_code, item_name, brand, product_group, description, detailed_description,
                                sales_rate, cost_price, purchase_rate, wholesale_price, mrp,
                                profit_percentage, minimum_sale_rate, addin_part_number_1, addin_part_number_2,
                                image, other_language, quantity_on_hand, unit_of_measure,
                                low_stock_threshold, location_aisle, location_shelf,
                                location_bin, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(item_code) DO UPDATE SET
            item_name            = COALESCE(excluded.item_name, products.item_name),
            brand                = COALESCE(excluded.brand, products.brand),
            product_group        = COALESCE(excluded.product_group, products.product_group),
            detailed_description = COALESCE(excluded.detailed_description, products.detailed_description),
            description          = COALESCE(excluded.description, products.description),
            sales_rate           = COALESCE(excluded.sales_rate, products.sales_rate),
            purchase_rate        = COALESCE(excluded.purchase_rate, products.purchase_rate),
            wholesale_price      = COALESCE(excluded.wholesale_price, products.wholesale_price),
            mrp                  = COALESCE(excluded.mrp, products.mrp),
            profit_percentage    = COALESCE(excluded.profit_percentage, products.profit_percentage),
            minimum_sale_rate    = COALESCE(excluded.minimum_sale_rate, products.minimum_sale_rate),
            addin_part_number_1  = COALESCE(excluded.addin_part_number_1, products.addin_part_number_1),
            addin_part_number_2  = COALESCE(excluded.addin_part_number_2, products.addin_part_number_2),
            image                = COALESCE(excluded.image, products.image),
            other_language       = COALESCE(excluded.other_language, products.other_language),
            quantity_on_hand     = products.quantity_on_hand + excluded.quantity_on_hand,
            unit_of_measure      = COALESCE(excluded.unit_of_measure, products.unit_of_measure),
            updated_at           = ?
        ''',
          [
            p.itemCode,
            p.itemName,
            p.brand,
            p.productGroup,
            p.description,
            p.detailedDescription,
            p.salesRate,
            p.costPrice,
            p.purchaseRate,
            p.wholesalePrice,
            p.mrp,
            p.profitPercentage,
            p.minimumSaleRate,
            p.addinPartNumber1,
            p.addinPartNumber2,
            p.image,
            p.otherLanguage,
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
        // Look up the product IDs by itemCode for this chunk.
        final itemCodes = productsWithMeta.map((p) => p.itemCode).toList();
        final placeholders = List.filled(itemCodes.length, '?').join(',');
        final idRows = await db.rawQuery(
          'SELECT id, item_code FROM products WHERE item_code IN ($placeholders)',
          itemCodes,
        );
        final itemCodeToId = <String, int>{};
        for (final row in idRows) {
          itemCodeToId[row['item_code'] as String] = row['id'] as int;
        }

        final metaBatch = db.batch();
        for (final p in productsWithMeta) {
          final productId = itemCodeToId[p.itemCode];
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
      'SELECT COALESCE(SUM(sales_rate * quantity_on_hand), 0) as total FROM products',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getPotentialProfit() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM((sales_rate - cost_price) * quantity_on_hand), 0) as profit FROM products',
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
