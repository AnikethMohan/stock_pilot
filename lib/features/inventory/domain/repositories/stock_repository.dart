import 'package:stock_pilot/features/inventory/domain/entities/inventory_import.dart';
import 'package:stock_pilot/features/inventory/domain/entities/stock_movement.dart';

abstract class StockRepository {
  /// Updates product stock by applying a exact [delta].
  /// Logs a record in stock_movements.
  Future<void> updateQuantity({
    required int productId,
    required double delta,
    required String movementType,
    String? referenceId,
    String? notes,
  });

  /// Processes bulk CSV rows containing products and applies delta changes.
  /// Records an import batch and individual movements in a single atomic transaction.
  /// Runs parsing on an Isolate.
  Future<InventoryImport> importCsvBulk(String filename, String csvString);

  /// Safely reverses an import by an [importId].
  /// Fails before applying if reversing causes negative stock on any product.
  Future<void> reverseImport(int importId);

  /// Retrieves chronological stock movements for a product.
  Future<List<StockMovement>> getProductMovements(int productId);

  /// Retrieves past CSV imports.
  Future<List<InventoryImport>> getImports();
}
