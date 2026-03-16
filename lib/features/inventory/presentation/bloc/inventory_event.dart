/// Inventory BLoC events.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';

sealed class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends InventoryEvent {
  const LoadProducts({this.searchQuery, this.productGroup, this.lowStockOnly});
  final String? searchQuery;
  final String? productGroup;
  final bool? lowStockOnly;

  @override
  List<Object?> get props => [searchQuery, productGroup, lowStockOnly];
}

class AddProduct extends InventoryEvent {
  const AddProduct(this.product);
  final Product product;

  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends InventoryEvent {
  const UpdateProduct(this.product);
  final Product product;

  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends InventoryEvent {
  const DeleteProduct(this.productId);
  final int productId;

  @override
  List<Object?> get props => [productId];
}

class AdjustStock extends InventoryEvent {
  const AdjustStock({
    required this.productId,
    required this.changeAmount,
    required this.reason,
    this.notes = '',
  });
  final int productId;
  final double changeAmount;
  final TransactionReason reason;
  final String notes;

  @override
  List<Object?> get props => [productId, changeAmount, reason, notes];
}

class ImportCsv extends InventoryEvent {
  const ImportCsv(this.csvContent);
  final String csvContent;

  @override
  List<Object?> get props => [csvContent];
}

class ExportCsv extends InventoryEvent {
  const ExportCsv();
}

class LoadMoreProducts extends InventoryEvent {
  const LoadMoreProducts();
}
