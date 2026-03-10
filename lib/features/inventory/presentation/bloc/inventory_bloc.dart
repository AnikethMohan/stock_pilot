/// Inventory BLoC — orchestrates product CRUD, stock adjustments, and CSV ops.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/core/utils/csv_service.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({required InventoryRepository repository})
    : _repository = repository,
      super(const InventoryInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadMoreProducts>(_onLoadMore);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<AdjustStock>(_onAdjustStock);
    on<ImportCsv>(_onImportCsv);
    on<ExportCsv>(_onExportCsv);
  }

  final InventoryRepository _repository;

  static const int _pageSize = 50;

  // Track current filter state for "load more".
  String? _lastSearchQuery;
  String? _lastCategory;
  bool? _lastLowStockOnly;

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      // Save filters for pagination.
      _lastSearchQuery = event.searchQuery;
      _lastCategory = event.category;
      _lastLowStockOnly = event.lowStockOnly;

      final products = await _repository.getProducts(
        searchQuery: event.searchQuery,
        category: event.category,
        lowStockOnly: event.lowStockOnly,
        limit: _pageSize,
        offset: 0,
      );
      final totalCount = await _repository.getProductCount(
        searchQuery: event.searchQuery,
        category: event.category,
        lowStockOnly: event.lowStockOnly,
      );
      final categories = await _repository.getCategories();
      emit(
        InventoryLoaded(
          products: products,
          categories: categories,
          totalProductCount: totalCount,
          hasMore: products.length < totalCount,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreProducts event,
    Emitter<InventoryState> emit,
  ) async {
    final current = state;
    if (current is! InventoryLoaded || !current.hasMore) return;

    try {
      final nextPage = await _repository.getProducts(
        searchQuery: _lastSearchQuery,
        category: _lastCategory,
        lowStockOnly: _lastLowStockOnly,
        limit: _pageSize,
        offset: current.products.length,
      );

      final allProducts = [...current.products, ...nextPage];
      emit(
        InventoryLoaded(
          products: allProducts,
          categories: current.categories,
          totalProductCount: current.totalProductCount,
          hasMore: allProducts.length < current.totalProductCount,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.addProduct(event.product);
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.updateProduct(event.product);
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.deleteProduct(event.productId);
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.adjustStock(
        productId: event.productId,
        changeAmount: event.changeAmount,
        reason: event.reason,
        notes: event.notes,
      );
      add(const LoadProducts());
    } on NegativeStockFailure catch (e) {
      emit(InventoryError(e.message));
      // Reload current state so UI can show the error and still display data
      add(const LoadProducts());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onImportCsv(
    ImportCsv event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      // Stage 1: Parse on isolate
      emit(
        const CsvImporting(
          progress: 0,
          processed: 0,
          total: 0,
          stage: 'Parsing CSV…',
        ),
      );

      final products = await CsvService.parseCsvAsync(event.csvContent);

      // Stage 2: Chunked DB upsert with progress reporting
      emit(
        CsvImporting(
          progress: 0,
          processed: 0,
          total: products.length,
          stage: 'Writing to database…',
        ),
      );

      final count = await _repository.upsertProductsFromCsv(
        products,
        onProgress: (processed, total) {
          // We can't emit inside a callback, so we use an approximation.
          // The final count will be accurate.
          emit(
            CsvImporting(
              progress: total > 0 ? processed / total : 0,
              processed: processed,
              total: total,
              stage: 'Writing to database…',
            ),
          );
        },
      );

      // Stage 3: Load first page
      final allProducts = await _repository.getProducts(
        limit: _pageSize,
        offset: 0,
      );
      final totalCount = await _repository.getProductCount();
      final categories = await _repository.getCategories();
      emit(
        InventoryLoaded(
          products: allProducts,
          categories: categories,
          csvImportCount: count,
          totalProductCount: totalCount,
          hasMore: allProducts.length < totalCount,
        ),
      );
    } catch (e) {
      emit(InventoryError('CSV Import failed: ${e.toString()}'));
    }
  }

  Future<void> _onExportCsv(
    ExportCsv event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      // For export we need ALL products, use a large limit.
      final products = await _repository.getProducts(limit: 100000, offset: 0);
      final csvData = CsvService.exportToCsv(products);
      final categories = await _repository.getCategories();
      final totalCount = await _repository.getProductCount();
      emit(
        InventoryLoaded(
          products: products.take(_pageSize).toList(),
          categories: categories,
          csvExportData: csvData,
          totalProductCount: totalCount,
          hasMore: products.length > _pageSize,
        ),
      );
    } catch (e) {
      emit(InventoryError('CSV Export failed: ${e.toString()}'));
    }
  }
}
