import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/database/database_helper.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/core/utils/csv_service.dart';
import 'package:stock_pilot/features/inventory/domain/entities/inventory_import.dart';
import 'package:stock_pilot/features/inventory/domain/entities/stock_movement.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  StockRepositoryImpl({DatabaseHelper? databaseHelper})
    : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<void> updateQuantity({
    required int productId,
    required double delta,
    required String movementType,
    String? referenceId,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final res = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (res.isEmpty)
        throw const DatabaseFailure('Product not found for updateQuantity');

      final currentQty = (res.first['quantity_on_hand'] as num).toDouble();
      final newQty = currentQty + delta;

      // Check negative stock
      if (newQty < 0) {
        final settingMap = await txn.query(
          'settings',
          where: 'key = ?',
          whereArgs: [SettingsKeys.allowNegativeStock],
        );
        final allowNeg = settingMap.isNotEmpty
            ? settingMap.first['value'] as String
            : 'false';
        if (allowNeg != 'true') {
          throw const NegativeStockFailure();
        }
      }

      await txn.update(
        'products',
        {
          'quantity_on_hand': newQty,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      final movement = StockMovement(
        productId: productId,
        quantityDelta: delta,
        movementType: movementType,
        referenceId: referenceId,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await txn.insert('stock_movements', movement.toMap());
    });
  }

  @override
  Future<InventoryImport> importCsvBulk(
    String filename,
    String csvString,
  ) async {
    // 1. Offload Heavy Parsing String -> List<Product> mapping (Isolate)
    final products = await CsvService.parseCsvAsync(csvString);
    if (products.isEmpty) {
      throw const FormatException('CSV contains no data');
    }

    final db = await _dbHelper.database;
    InventoryImport? importRecord;

    // 2. Wrap all database logic inside a massive atomic batch
    await db.transaction((txn) async {
      // Create import record
      final metadata = InventoryImport(
        filename: filename,
        date: DateTime.now(),
        totalRows: products.length,
      );
      final importId = await txn.insert('inventory_imports', metadata.toMap());
      importRecord = InventoryImport(
        id: importId,
        filename: metadata.filename,
        date: metadata.date,
        totalRows: metadata.totalRows,
      );

      final batch = txn.batch();

      // Because we need the *current* DB stock to calculate Delta, we can query it inside the loop,
      // or we can pre-fetch all matching product codes in one query for faster resolution.
      final itemCodes = products.map((e) => "'${e.itemCode}'").join(',');

      // Prevent SQL Syntax exception if string is too long or empty
      final currentProductsRaw = await txn.rawQuery(
        'SELECT id, item_code, quantity_on_hand FROM products WHERE item_code IN ($itemCodes)',
      );

      final existingProductsMap = {
        for (final row in currentProductsRaw)
          row['item_code'] as String: {
            'id': row['id'] as int,
            'qty': (row['quantity_on_hand'] as num).toDouble(),
          },
      };

      for (final p in products) {
        final existingInfo = existingProductsMap[p.itemCode];

        int pId;
        double currentQty;

        if (existingInfo != null) {
          // Product exists, update it.
          pId = existingInfo['id'] as int;
          currentQty = existingInfo['qty'] as double;

          final csvQty =
              p.quantityOnHand; // The value from CSV acts as the delta
          final delta = csvQty;
          final newQty = currentQty + delta;

          // Safely build the update map so we don't overwrite existing filled fields with 0.0 or ''
          final updateMap = <String, dynamic>{
            'quantity_on_hand': newQty, // Updated to add the quantity
            'updated_at': DateTime.now().toIso8601String(),
          };

          if (p.itemName.isNotEmpty) updateMap['item_name'] = p.itemName;
          if (p.brand.isNotEmpty) updateMap['brand'] = p.brand;
          if (p.productGroup != null && p.productGroup!.isNotEmpty)
            updateMap['product_group'] = p.productGroup;
          if (p.description.isNotEmpty)
            updateMap['description'] = p.description;
          if (p.detailedDescription != null &&
              p.detailedDescription!.isNotEmpty)
            updateMap['detailed_description'] = p.detailedDescription;
          if (p.salesRate > 0) updateMap['sales_rate'] = p.salesRate;
          if (p.costPrice > 0) updateMap['cost_price'] = p.costPrice;
          if (p.purchaseRate > 0) updateMap['purchase_rate'] = p.purchaseRate;
          if (p.wholesalePrice > 0)
            updateMap['wholesale_price'] = p.wholesalePrice;
          if (p.mrp > 0) updateMap['mrp'] = p.mrp;
          if (p.profitPercentage > 0)
            updateMap['profit_percentage'] = p.profitPercentage;
          if (p.minimumSaleRate > 0)
            updateMap['minimum_sale_rate'] = p.minimumSaleRate;
          if (p.addinPartNumber1.isNotEmpty)
            updateMap['addin_part_number_1'] = p.addinPartNumber1;
          if (p.addinPartNumber2.isNotEmpty)
            updateMap['addin_part_number_2'] = p.addinPartNumber2;
          if (p.image.isNotEmpty) updateMap['image'] = p.image;
          if (p.otherLanguage.isNotEmpty)
            updateMap['other_language'] = p.otherLanguage;

          batch.update(
            'products',
            updateMap,
            where: 'id = ?',
            whereArgs: [pId],
          );

          if (delta != 0) {
            batch.insert(
              'stock_movements',
              StockMovement(
                productId: pId,
                quantityDelta: delta,
                movementType: TransactionReason.csvImport.label,
                referenceId: importId.toString(),
                timestamp: DateTime.now(),
              ).toMap(),
            );
          }
        } else {
          // It's a brand new product
          currentQty = 0;
          final delta = p.quantityOnHand;

          // Using a prepared insert because batch doesn't return the inserted ID until commit.
          // Wait, if it's new, we need its ID for stock_movements. A raw txn.insert inside loop is better than batch
          // if we must get the ID synchronously.
          final insertMap = {
            'item_code': p.itemCode,
            'barcode': p.barcode,
            'item_name': p.itemName,
            'brand': p.brand,
            'product_group': p.productGroup,
            'description': p.description,
            'detailed_description': p.detailedDescription,
            'sales_rate': p.salesRate,
            'cost_price': p.costPrice,
            'purchase_rate': p.purchaseRate,
            'wholesale_price': p.wholesalePrice,
            'mrp': p.mrp,
            'profit_percentage': p.profitPercentage,
            'minimum_sale_rate': p.minimumSaleRate,
            'addin_part_number_1': p.addinPartNumber1,
            'addin_part_number_2': p.addinPartNumber2,
            'image': p.image,
            'other_language': p.otherLanguage,
            'quantity_on_hand': p.quantityOnHand,
            'unit_of_measure': p.unitOfMeasure.label,
            'low_stock_threshold': p.lowStockThreshold,
            'location_aisle': p.locationAisle,
            'location_shelf': p.locationShelf,
            'location_bin': p.locationBin,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          final newProductId = await txn.insert('products', insertMap);

          if (delta != 0) {
            await txn.insert(
              'stock_movements',
              StockMovement(
                productId: newProductId,
                quantityDelta: delta,
                movementType: TransactionReason.csvImport.label,
                referenceId: importId.toString(),
                timestamp: DateTime.now(),
              ).toMap(),
            );
          }
        }
      }

      // Execute the batch containing all product updates.
      await batch.commit(noResult: true);
    });

    return importRecord!;
  }

  @override
  Future<void> reverseImport(int importId) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Find all movements
      final movementsRaw = await txn.query(
        'stock_movements',
        where: 'reference_id = ? AND movement_type = ?',
        whereArgs: [importId.toString(), TransactionReason.csvImport.label],
      );

      final movements = movementsRaw
          .map((m) => StockMovement.fromMap(m))
          .toList();
      if (movements.isEmpty) {
        // Nothing to reverse, or already reversed
        return;
      }

      // Check allowNegative setting
      final settingMap = await txn.query(
        'settings',
        where: 'key = ?',
        whereArgs: [SettingsKeys.allowNegativeStock],
      );
      final allowNeg =
          settingMap.isNotEmpty && settingMap.first['value'] == 'true';

      // Pre-flight negative stock check
      for (final m in movements) {
        final res = await txn.query(
          'products',
          columns: ['id', 'item_code', 'quantity_on_hand'],
          where: 'id = ?',
          whereArgs: [m.productId],
        );

        if (res.isNotEmpty) {
          final currentQty = (res.first['quantity_on_hand'] as num).toDouble();
          final inverseDelta = -m.quantityDelta;
          final newQty = currentQty + inverseDelta;

          if (newQty < 0 && !allowNeg) {
            final itemCode = res.first['item_code'] as String;
            throw CsvFailure(
              'Cannot undo import. Reversing would result in negative stock ($newQty) for $itemCode.',
            );
          }
        }
      }

      // If pre-flight passes, safely reverse
      for (final m in movements) {
        final res = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [m.productId],
        );
        if (res.isNotEmpty) {
          final currentQty = (res.first['quantity_on_hand'] as num).toDouble();
          final inverseDelta = -m.quantityDelta;
          final newQty = currentQty + inverseDelta;

          await txn.update(
            'products',
            {
              'quantity_on_hand': newQty,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [m.productId],
          );

          // Delete the original stock_movement history, or add a counter movement?
          // Usually, "Undo" deletes the history to pretend it never happened,
          // or logs an explicit reverse movement. Let's delete it so the history is clean.
          await txn.delete(
            'stock_movements',
            where: 'id = ?',
            whereArgs: [m.id],
          );
        }
      }

      // Finally remove the import record
      await txn.delete(
        'inventory_imports',
        where: 'id = ?',
        whereArgs: [importId],
      );
    });
  }

  @override
  Future<List<StockMovement>> getProductMovements(int productId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
    return res.map((m) => StockMovement.fromMap(m)).toList();
  }

  @override
  Future<List<InventoryImport>> getImports() async {
    final db = await _dbHelper.database;
    final res = await db.query('inventory_imports', orderBy: 'date DESC');
    return res.map((m) => InventoryImport.fromMap(m)).toList();
  }
}
