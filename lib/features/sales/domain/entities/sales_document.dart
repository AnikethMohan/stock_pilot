/// SalesDocument entity — unified representation for quotations, delivery notes, and invoices.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';

class SalesDocument extends Equatable {
  const SalesDocument({
    this.id,
    required this.docType,
    required this.docNumber,
    this.customer,
    this.customerId,
    this.supplier,
    this.supplierId,
    this.items = const [],
    this.derivedDocuments = const [],
    this.subtotal = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.grandTotal = 0.0,
    this.status = DocStatus.draft,
    this.sourceDocId,
    this.sourceDocNumber,
    this.deliveryDate,
    this.paymentStatus,
    this.notes = '',
    this.createdAt,
  });

  final int? id;
  final DocType docType;
  final String docNumber;
  final Customer? customer;
  final int? customerId;
  final Supplier? supplier;
  final int? supplierId;
  final List<SalesDocItem> items;
  final List<SalesDocument> derivedDocuments;
  final double subtotal;
  final double discountPercent; // Used as Global Discount Percent
  final double discountAmount; // Used as Global Discount Amount
  final double taxAmount;
  final double grandTotal;
  final DocStatus status;
  final int? sourceDocId;
  final String? sourceDocNumber;
  final DateTime? deliveryDate;
  final String? paymentStatus;
  final String notes;
  final DateTime? createdAt;

  /// Recalculate all totals from current items and global discount.
  SalesDocument recalculate({
    double? newGlobalDiscount,
    double? newGlobalDiscountPercent,
  }) {
    final sub = items.fold<double>(
      0,
      (sum, i) => sum + (i.unitPrice * i.quantity),
    );
    final tax = items.fold<double>(0, (sum, i) => sum + i.taxAmount);
    final totalLineItems = items.fold<double>(0, (sum, i) => sum + i.lineTotal);

    double globalDisc = newGlobalDiscount ?? discountAmount;
    double globalDiscPct = newGlobalDiscountPercent ?? discountPercent;

    if (newGlobalDiscountPercent != null) {
      globalDisc = sub * (newGlobalDiscountPercent / 100);
    } else if (newGlobalDiscount != null) {
      globalDiscPct = sub > 0 ? (newGlobalDiscount / sub) * 100 : 0.0;
    } else {
      // Refresh global discount amount based on current subtotal if percent exists
      if (globalDiscPct > 0) {
        globalDisc = sub * (globalDiscPct / 100);
      }
    }

    // Grand total is the sum of all item line totals (which already account for item-level discounts and tax)
    // minus the global document-level discount.
    final grand = totalLineItems - globalDisc;

    return copyWith(
      subtotal: sub,
      discountPercent: globalDiscPct,
      discountAmount: globalDisc,
      taxAmount: tax,
      grandTotal: grand,
    );
  }

  /// Total discount including item-level and global discounts.
  double get totalDiscountCalculated {
    final itemDiscs = items.fold<double>(0, (sum, i) => sum + i.discountAmount);
    return itemDiscs + discountAmount;
  }

  SalesDocument copyWith({
    Object? id = const Object(),
    DocType? docType,
    String? docNumber,
    Customer? customer,
    int? customerId,
    Supplier? supplier,
    int? supplierId,
    List<SalesDocItem>? items,
    List<SalesDocument>? derivedDocuments,
    double? subtotal,
    double? discountPercent,
    double? discountAmount,
    double? taxAmount,
    double? grandTotal,
    DocStatus? status,
    int? sourceDocId,
    String? sourceDocNumber,
    DateTime? deliveryDate,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return SalesDocument(
      id: id == const Object() ? this.id : id as int?,
      docType: docType ?? this.docType,
      docNumber: docNumber ?? this.docNumber,
      customer: customer ?? this.customer,
      customerId: customerId ?? this.customerId,
      supplier: supplier ?? this.supplier,
      supplierId: supplierId ?? this.supplierId,
      items: items ?? this.items,
      derivedDocuments: derivedDocuments ?? this.derivedDocuments,
      subtotal: subtotal ?? this.subtotal,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      sourceDocId: sourceDocId ?? this.sourceDocId,
      sourceDocNumber: sourceDocNumber ?? this.sourceDocNumber,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    docType,
    docNumber,
    customer,
    customerId,
    supplier,
    supplierId,
    items,
    derivedDocuments,
    subtotal,
    discountPercent,
    discountAmount,
    taxAmount,
    grandTotal,
    status,
    sourceDocId,
    sourceDocNumber,
    deliveryDate,
    paymentStatus,
    notes,
    createdAt,
  ];
}

/// A single line item on a sales document.
class SalesDocItem extends Equatable {
  const SalesDocItem({
    this.id,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.lineTotal = 0,
  });

  final int? id;
  final int productId;
  final String sku;
  final String productName;
  final double unitPrice;
  final double quantity;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double lineTotal;

  /// Create with auto-calculated totals.
  factory SalesDocItem.create({
    int? id,
    required int productId,
    required String sku,
    required String productName,
    required double unitPrice,
    double quantity = 1,
    double discountPercent = 0.0,
    double taxPercent = 0.0,
  }) {
    final gross = unitPrice * quantity;
    final discAmt = gross * (discountPercent / 100);
    final afterDiscount = gross - discAmt;
    final taxAmt = afterDiscount * (taxPercent / 100);
    return SalesDocItem(
      id: id,
      productId: productId,
      sku: sku,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity,
      discountPercent: discountPercent,
      discountAmount: discAmt,
      taxPercent: taxPercent,
      taxAmount: taxAmt,
      lineTotal: afterDiscount + taxAmt,
    );
  }

  /// Recalculate this item's amounts.
  SalesDocItem recalculate() {
    final gross = unitPrice * quantity;
    final discAmt = gross * (discountPercent / 100);
    final afterDiscount = gross - discAmt;
    final taxAmt = afterDiscount * (taxPercent / 100);
    return SalesDocItem(
      id: id,
      productId: productId,
      sku: sku,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity,
      discountPercent: discountPercent,
      discountAmount: discAmt,
      taxPercent: taxPercent,
      taxAmount: taxAmt,
      lineTotal: afterDiscount + taxAmt,
    );
  }

  SalesDocItem copyWith({
    Object? id = const Object(),
    int? productId,
    String? sku,
    String? productName,
    double? unitPrice,
    double? quantity,
    double? discountPercent,
    double? taxPercent,
  }) {
    return SalesDocItem.create(
      id: id == const Object() ? this.id : id as int?,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    sku,
    productName,
    unitPrice,
    quantity,
    discountPercent,
    discountAmount,
    taxPercent,
    taxAmount,
    lineTotal,
  ];
}
