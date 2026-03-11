/// Abstract inventory repository — defines the contract for all product CRUD.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

abstract class InventoryRepository {
  /// Get products with optional filters and pagination.
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    int limit,
    int offset,
  });

  /// Get total product count for the given filters (for pagination).
  Future<int> getProductCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
  });

  /// Get a single product by ID.
  Future<Product?> getProductById(int id);

  /// Get a single product by SKU.
  Future<Product?> getProductBySku(String sku);

  /// Add a new product, returns its ID.
  Future<int> addProduct(Product product);

  /// Update an existing product.
  Future<void> updateProduct(Product product);

  /// Delete a product by ID.
  Future<void> deleteProduct(int id);

  /// Adjust stock for a product and log a transaction.
  /// Returns the updated Product.
  Future<Product> adjustStock({
    required int productId,
    required double changeAmount,
    required TransactionReason reason,
    String notes,
  });

  /// Get all distinct categories.
  Future<List<String>> getCategories();

  /// CSV Upsert — insert or increment stock for a batch of products.
  /// Calls [onProgress] with (processedCount, totalCount) during import.
  Future<int> upsertProductsFromCsv(
    List<Product> products, {
    void Function(int processed, int total)? onProgress,
  });

  // ─── Dashboard aggregations ──────────────────────────────────────

  /// Sum of (unit_price * quantity_on_hand) for all products.
  Future<double> getTotalInventoryValue();

  /// Returns the total potential profit based on current stock.
  Future<double> getPotentialProfit();

  /// Number of products where quantity_on_hand <= low_stock_threshold.
  Future<int> getLowStockCount();
}

abstract class TransactionRepository {
  Future<List<StockTransaction>> getTransactions({
    int? productId,
    int limit,
    int offset,
  });

  Future<List<StockTransaction>> getRecentTransactions({int limit = 10});
}

abstract class SettingsRepository {
  Future<bool> getAllowNegativeStock();
  Future<void> setAllowNegativeStock(bool value);
  Future<double> getDefaultLowStockThreshold();
  Future<void> setDefaultLowStockThreshold(double value);
  Future<String> getDefaultCurrency();
  Future<void> setDefaultCurrency(String code);

  // Business Info
  Future<String> getBusinessName();
  Future<void> setBusinessName(String value);
  Future<String> getBusinessAddress();
  Future<void> setBusinessAddress(String value);
  Future<String> getBusinessPhone();
  Future<void> setBusinessPhone(String value);
  Future<String> getBusinessEmail();
  Future<void> setBusinessEmail(String value);
  Future<String> getBusinessWebsite();
  Future<void> setBusinessWebsite(String value);
}
