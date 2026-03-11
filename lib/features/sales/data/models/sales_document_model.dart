/// Data model for SalesDocument / SalesDocItem — handles SQLite map conversions.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';

class SalesDocumentModel {
  SalesDocumentModel._();

  static Map<String, dynamic> toMap(SalesDocument doc) {
    final now = DateTime.now().toIso8601String();
    return {
      if (doc.id != null) 'id': doc.id,
      'doc_type': doc.docType.value,
      'doc_number': doc.docNumber,
      'customer_id': doc.customerId,
      'supplier_id': doc.supplierId,
      'subtotal': doc.subtotal,
      'discount_percent': doc.discountPercent,
      'discount_amount': doc.discountAmount,
      'tax_amount': doc.taxAmount,
      'grand_total': doc.grandTotal,
      'status': doc.status.value,
      'source_doc_id': doc.sourceDocId,
      'source_doc_number': doc.sourceDocNumber,
      'delivery_date': doc.deliveryDate?.toIso8601String(),
      'payment_status': doc.paymentStatus,
      'notes': doc.notes,
      'created_at': doc.createdAt?.toIso8601String() ?? now,
    };
  }

  static SalesDocument fromMap(
    Map<String, dynamic> map, {
    List<SalesDocItem> items = const [],
    List<SalesDocument> derivedDocuments = const [],
    Customer? customer,
    Supplier? supplier,
  }) {
    final custId = map['customer_id'] as int?;
    final suppId = map['supplier_id'] as int?;
    return SalesDocument(
      id: map['id'] as int?,
      docType: DocType.fromString((map['doc_type'] as String?) ?? 'invoice'),
      docNumber: map['doc_number'] as String,
      customerId: custId,
      customer:
          customer ??
          (custId == null &&
                  !(map['doc_type'] == 'purchase_order' ||
                      map['doc_type'] == 'material_receipt' ||
                      map['doc_type'] == 'purchase_invoice')
              ? const Customer(name: AppDefaults.defaultCustomerName)
              : null),
      supplierId: suppId,
      supplier: supplier,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      status: DocStatus.fromString((map['status'] as String?) ?? 'draft'),
      sourceDocId: map['source_doc_id'] as int?,
      sourceDocNumber: map['source_doc_number'] as String?,
      deliveryDate: map['delivery_date'] != null
          ? DateTime.tryParse(map['delivery_date'] as String)
          : null,
      paymentStatus: map['payment_status'] as String?,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      items: items,
      derivedDocuments: derivedDocuments,
    );
  }
}

class SalesDocItemModel {
  SalesDocItemModel._();

  static Map<String, dynamic> toMap(SalesDocItem item, int documentId) {
    return {
      if (item.id != null) 'id': item.id,
      'document_id': documentId,
      'product_id': item.productId,
      'sku': item.sku,
      'product_name': item.productName,
      'unit_price': item.unitPrice,
      'quantity': item.quantity,
      'discount_percent': item.discountPercent,
      'discount_amount': item.discountAmount,
      'tax_percent': item.taxPercent,
      'tax_amount': item.taxAmount,
      'line_total': item.lineTotal,
    };
  }

  static SalesDocItem fromMap(Map<String, dynamic> map) {
    return SalesDocItem(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }
}
