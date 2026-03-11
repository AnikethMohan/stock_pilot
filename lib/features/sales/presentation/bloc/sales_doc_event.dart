/// Events for the SalesDoc BLoC.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';

sealed class SalesDocEvent extends Equatable {
  const SalesDocEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize a new draft document or load an existing one.
class StartNewDocument extends SalesDocEvent {
  const StartNewDocument({this.type, this.existing});
  final DocType? type;
  final SalesDocument? existing;

  @override
  List<Object?> get props => [type, existing];
}

/// Change the document type of the active draft.
class SetDocType extends SalesDocEvent {
  const SetDocType(this.type);
  final DocType type;

  @override
  List<Object?> get props => [type];
}

/// Load the list of past documents.
class LoadDocuments extends SalesDocEvent {
  const LoadDocuments({this.typeFilter, this.limit = 50, this.offset = 0});
  final DocType? typeFilter;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [typeFilter, limit, offset];
}

/// Add a line item to the active draft.
class AddDocItem extends SalesDocEvent {
  const AddDocItem({required this.product, this.quantity = 1});
  final Product product;
  final double quantity;

  @override
  List<Object?> get props => [product, quantity];
}

/// Remove a line item by sku.
class RemoveDocItem extends SalesDocEvent {
  const RemoveDocItem(this.sku);
  final String sku;

  @override
  List<Object?> get props => [sku];
}

/// Update quantity of an existing line item.
class UpdateItemQuantity extends SalesDocEvent {
  const UpdateItemQuantity({required this.sku, required this.quantity});
  final String sku;
  final double quantity;

  @override
  List<Object?> get props => [sku, quantity];
}

/// Update the unit price of a line item.
class UpdateItemPrice extends SalesDocEvent {
  const UpdateItemPrice({required this.sku, required this.price});
  final String sku;
  final double price;

  @override
  List<Object?> get props => [sku, price];
}

/// Update the discount percent of a line item.
class UpdateItemDiscount extends SalesDocEvent {
  const UpdateItemDiscount({required this.sku, required this.discountPercent});
  final String sku;
  final double discountPercent;

  @override
  List<Object?> get props => [sku, discountPercent];
}

/// Update the discount amount of a line item.
class UpdateItemDiscountAmount extends SalesDocEvent {
  const UpdateItemDiscountAmount({
    required this.sku,
    required this.discountAmount,
  });
  final String sku;
  final double discountAmount;

  @override
  List<Object?> get props => [sku, discountAmount];
}

/// Update the tax percent of a line item.
class UpdateItemTax extends SalesDocEvent {
  const UpdateItemTax({required this.sku, required this.taxPercent});
  final String sku;
  final double taxPercent;

  @override
  List<Object?> get props => [sku, taxPercent];
}

/// Set the customer for the active document.
class SelectCustomer extends SalesDocEvent {
  const SelectCustomer(this.customer);
  final Customer customer;

  @override
  List<Object?> get props => [customer];
}

/// Set the supplier for the active document.
class SelectSupplier extends SalesDocEvent {
  const SelectSupplier(this.supplier);
  final Supplier supplier;

  @override
  List<Object?> get props => [supplier];
}

/// Update global discount percent.
class UpdateGlobalDiscount extends SalesDocEvent {
  const UpdateGlobalDiscount(this.discountPercent);
  final double discountPercent;

  @override
  List<Object?> get props => [discountPercent];
}

/// Update global discount amount.
class UpdateGlobalDiscountAmount extends SalesDocEvent {
  const UpdateGlobalDiscountAmount(this.discountAmount);
  final double discountAmount;

  @override
  List<Object?> get props => [discountAmount];
}

/// Update notes.
class UpdateNotes extends SalesDocEvent {
  const UpdateNotes(this.notes);
  final String notes;

  @override
  List<Object?> get props => [notes];
}

/// Save the active document as a draft.
class SaveDraft extends SalesDocEvent {
  const SaveDraft();
}

/// Finalize and confirm the document.
class ConfirmDocument extends SalesDocEvent {
  const ConfirmDocument();
}

/// Convert a source document to a different type.
class ConvertDocument extends SalesDocEvent {
  const ConvertDocument({required this.sourceDocId, required this.targetType});
  final int sourceDocId;
  final DocType targetType;

  @override
  List<Object?> get props => [sourceDocId, targetType];
}
