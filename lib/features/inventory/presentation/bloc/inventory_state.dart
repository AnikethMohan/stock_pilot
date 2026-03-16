/// Inventory BLoC states.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';

sealed class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// CSV import in progress with progress reporting.
class CsvImporting extends InventoryState {
  const CsvImporting({
    required this.progress,
    required this.processed,
    required this.total,
    this.stage = 'Importing…',
  });
  final double progress; // 0.0 – 1.0
  final int processed;
  final int total;
  final String stage;

  @override
  List<Object?> get props => [progress, processed, total, stage];
}

class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.products,
    this.productGroups = const [],
    this.csvExportData,
    this.csvImportCount,
    this.totalProductCount = 0,
    this.hasMore = false,
  });
  final List<Product> products;
  final List<String> productGroups;
  final String? csvExportData;
  final int? csvImportCount;
  final int totalProductCount;
  final bool hasMore;

  @override
  List<Object?> get props => [
    products,
    productGroups,
    csvExportData,
    csvImportCount,
    totalProductCount,
    hasMore,
  ];
}

class InventoryError extends InventoryState {
  const InventoryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
