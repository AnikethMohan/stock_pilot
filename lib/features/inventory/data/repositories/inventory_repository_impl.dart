/// Concrete implementation of [InventoryRepository], [TransactionRepository],
/// and [SettingsRepository]  — delegates to local data source.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({InventoryLocalDataSource? dataSource})
    : _ds = dataSource ?? InventoryLocalDataSource();

  final InventoryLocalDataSource _ds;

  @override
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
    int limit = 50,
    int offset = 0,
  }) => _ds.getProducts(
    searchQuery: searchQuery,
    category: category,
    lowStockOnly: lowStockOnly,
    limit: limit,
    offset: offset,
  );

  @override
  Future<int> getProductCount({
    String? searchQuery,
    String? category,
    bool? lowStockOnly,
  }) => _ds.getProductCount(
    searchQuery: searchQuery,
    category: category,
    lowStockOnly: lowStockOnly,
  );

  @override
  Future<Product?> getProductById(int id) => _ds.getProductById(id);

  @override
  Future<Product?> getProductBySku(String sku) => _ds.getProductBySku(sku);

  @override
  Future<int> addProduct(Product product) => _ds.insertProduct(product);

  @override
  Future<void> updateProduct(Product product) => _ds.updateProduct(product);

  @override
  Future<void> deleteProduct(int id) => _ds.deleteProduct(id);

  @override
  Future<Product> adjustStock({
    required int productId,
    required double changeAmount,
    required TransactionReason reason,
    String notes = '',
  }) async {
    final product = await _ds.getProductById(productId);
    if (product == null) {
      throw const DatabaseFailure('Product not found.');
    }

    final newQty = product.quantityOnHand + changeAmount;

    // Negative-stock guard
    final allowNeg = await _ds.getSetting(SettingsKeys.allowNegativeStock);
    if (newQty < 0 && allowNeg != 'true') {
      throw const NegativeStockFailure();
    }

    await _ds.updateStock(productId, newQty);

    // Log transaction
    await _ds.insertTransaction(
      StockTransaction(
        productId: productId,
        sku: product.sku,
        timestamp: DateTime.now(),
        changeAmount: changeAmount,
        reason: reason,
        resultingTotal: newQty,
        notes: notes,
      ),
    );

    return (await _ds.getProductById(productId))!;
  }

  @override
  Future<List<String>> getCategories() => _ds.getCategories();

  @override
  Future<int> upsertProductsFromCsv(
    List<Product> products, {
    void Function(int processed, int total)? onProgress,
  }) => _ds.upsertProductsChunked(products, onProgress: onProgress);

  @override
  Future<double> getTotalInventoryValue() => _ds.getTotalInventoryValue();

  @override
  Future<int> getLowStockCount() => _ds.getLowStockCount();
}

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({InventoryLocalDataSource? dataSource})
    : _ds = dataSource ?? InventoryLocalDataSource();

  final InventoryLocalDataSource _ds;

  @override
  Future<List<StockTransaction>> getTransactions({
    int? productId,
    int limit = 50,
    int offset = 0,
  }) => _ds.getTransactions(productId: productId, limit: limit, offset: offset);

  @override
  Future<List<StockTransaction>> getRecentTransactions({int limit = 10}) =>
      _ds.getRecentTransactions(limit: limit);
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({InventoryLocalDataSource? dataSource})
    : _ds = dataSource ?? InventoryLocalDataSource();

  final InventoryLocalDataSource _ds;

  @override
  Future<bool> getAllowNegativeStock() async {
    final val = await _ds.getSetting(SettingsKeys.allowNegativeStock);
    return val == 'true';
  }

  @override
  Future<void> setAllowNegativeStock(bool value) =>
      _ds.setSetting(SettingsKeys.allowNegativeStock, value.toString());

  @override
  Future<double> getDefaultLowStockThreshold() async {
    final val = await _ds.getSetting(SettingsKeys.defaultLowStockThreshold);
    return double.tryParse(val ?? '') ?? AppDefaults.defaultLowStockThreshold;
  }

  @override
  Future<void> setDefaultLowStockThreshold(double value) =>
      _ds.setSetting(SettingsKeys.defaultLowStockThreshold, value.toString());

  @override
  Future<String> getDefaultCurrency() async {
    final val = await _ds.getSetting(SettingsKeys.defaultCurrency);
    return val ?? AppDefaults.defaultCurrencyCode;
  }

  @override
  Future<void> setDefaultCurrency(String code) =>
      _ds.setSetting(SettingsKeys.defaultCurrency, code);
}
