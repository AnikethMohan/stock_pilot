/// Local data source for Sales — raw SQLite operations for customers and sales documents.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/database/database_helper.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/features/sales/data/models/customer_model.dart';
import 'package:stock_pilot/features/sales/data/models/sales_document_model.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';
import 'package:stock_pilot/features/purchases/data/models/supplier_model.dart';
import 'package:stock_pilot/features/transactions/data/models/transaction_model.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

class SalesLocalDataSource {
  SalesLocalDataSource({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  // ─── Customers ───────────────────────────────────────────────────

  Future<List<Customer>> getCustomers({String? searchQuery}) async {
    final db = await _dbHelper.database;
    final where = (searchQuery != null && searchQuery.isNotEmpty)
        ? 'name LIKE ? OR phone LIKE ? OR email LIKE ?'
        : null;
    final whereArgs = where != null
        ? ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']
        : null;

    final rows = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return rows.map(CustomerModel.fromMap).toList();
  }

  Future<Customer> saveCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final map = CustomerModel.toMap(customer);

    if (customer.id == null) {
      final id = await db.insert('customers', map);
      return customer.copyWith(id: id);
    } else {
      await db.update(
        'customers',
        map,
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      return customer;
    }
  }

  // ─── Suppliers ───────────────────────────────────────────────────

  Future<List<Supplier>> getSuppliers({String? searchQuery}) async {
    final db = await _dbHelper.database;
    final where = (searchQuery != null && searchQuery.isNotEmpty)
        ? 'name LIKE ? OR phone LIKE ? OR email LIKE ?'
        : null;
    final whereArgs = where != null
        ? ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']
        : null;

    final rows = await db.query(
      'suppliers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return rows.map(SupplierModel.fromMap).toList();
  }

  Future<Supplier> saveSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    final map = SupplierModel.toMap(supplier);

    if (supplier.id == null) {
      final id = await db.insert('suppliers', map);
      return supplier.copyWith(id: id);
    } else {
      await db.update(
        'suppliers',
        map,
        where: 'id = ?',
        whereArgs: [supplier.id],
      );
      return supplier;
    }
  }

  // ─── Document Number Generation ──────────────────────────────────

  Future<String> getNextDocNumber(DocType type) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM sales_documents WHERE doc_type = ?",
      [type.value],
    );
    final count = (result.first['cnt'] as int?) ?? 0;
    final nextNum = count + 1;
    return '${type.prefix}-${nextNum.toString().padLeft(5, '0')}';
  }

  // ─── Sales Documents ────────────────────────────────────────────

  Future<List<SalesDocument>> getDocuments({
    DocType? typeFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = typeFilter != null ? 'doc_type = ?' : null;
    final whereArgs = typeFilter != null ? [typeFilter.value] : null;

    final rows = await db.query(
      'sales_documents',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final List<SalesDocument> docs = [];
    for (final r in rows) {
      final id = r['id'] as int;
      final customerId = r['customer_id'] as int?;

      Customer? customer;
      if (customerId != null) {
        final custRows = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [customerId],
        );
        if (custRows.isNotEmpty) {
          customer = CustomerModel.fromMap(custRows.first);
        }
      }

      final supplierId = r['supplier_id'] as int?;
      Supplier? supplier;
      if (supplierId != null) {
        final suppRows = await db.query(
          'suppliers',
          where: 'id = ?',
          whereArgs: [supplierId],
        );
        if (suppRows.isNotEmpty) {
          supplier = SupplierModel.fromMap(suppRows.first);
        }
      }

      final itemRows = await db.query(
        'sales_document_items',
        where: 'document_id = ?',
        whereArgs: [id],
      );
      final items = itemRows.map(SalesDocItemModel.fromMap).toList();
      docs.add(
        SalesDocumentModel.fromMap(
          r,
          items: items,
          customer: customer,
          supplier: supplier,
        ),
      );
    }

    return docs;
  }

  Future<SalesDocument> getDocumentById(int id) async {
    final db = await _dbHelper.database;

    final headerRows = await db.query(
      'sales_documents',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (headerRows.isEmpty) {
      throw const DatabaseFailure('Sales document not found');
    }

    final itemRows = await db.query(
      'sales_document_items',
      where: 'document_id = ?',
      whereArgs: [id],
    );
    final items = itemRows.map(SalesDocItemModel.fromMap).toList();

    final docMap = headerRows.first;
    final customerId = docMap['customer_id'] as int?;

    Customer? customer;
    if (customerId != null) {
      final custRows = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (custRows.isNotEmpty) {
        customer = CustomerModel.fromMap(custRows.first);
      }
    }

    final supplierId = docMap['supplier_id'] as int?;
    Supplier? supplier;
    if (supplierId != null) {
      final suppRows = await db.query(
        'suppliers',
        where: 'id = ?',
        whereArgs: [supplierId],
      );
      if (suppRows.isNotEmpty) {
        supplier = SupplierModel.fromMap(suppRows.first);
      }
    }

    final derivedRows = await db.query(
      'sales_documents',
      where: 'source_doc_id = ?',
      whereArgs: [id],
    );
    final derivedDocs = derivedRows
        .map((r) => SalesDocumentModel.fromMap(r))
        .toList();

    return SalesDocumentModel.fromMap(
      docMap,
      items: items,
      customer: customer,
      supplier: supplier,
      derivedDocuments: derivedDocs,
    );
  }

  /// Save a document as draft (insert or update).
  Future<SalesDocument> saveDocument(SalesDocument doc) async {
    final db = await _dbHelper.database;

    return db.transaction((txn) async {
      // Handle customer save
      int? customerId = doc.customerId;
      if (doc.customer != null &&
          doc.customer!.name != AppDefaults.defaultCustomerName) {
        final custMap = CustomerModel.toMap(doc.customer!);
        if (doc.customer!.id == null) {
          customerId = await txn.insert('customers', custMap);
        } else {
          await txn.update(
            'customers',
            custMap,
            where: 'id = ?',
            whereArgs: [doc.customer!.id],
          );
          customerId = doc.customer!.id;
        }
      } else if (doc.customer?.name == AppDefaults.defaultCustomerName) {
        customerId = null; // Do not save cash customer to DB
      }

      // Handle supplier save
      int? supplierId = doc.supplierId;
      if (doc.supplier != null) {
        final suppMap = SupplierModel.toMap(doc.supplier!);
        if (doc.supplier!.id == null) {
          supplierId = await txn.insert('suppliers', suppMap);
        } else {
          await txn.update(
            'suppliers',
            suppMap,
            where: 'id = ?',
            whereArgs: [doc.supplier!.id],
          );
          supplierId = doc.supplier!.id;
        }
      }

      final docToSave = doc.copyWith(
        customerId: customerId,
        supplierId: supplierId,
      );
      final docMap = SalesDocumentModel.toMap(docToSave);

      int returnedDocId;
      if (docToSave.id == null) {
        returnedDocId = await txn.insert('sales_documents', docMap);
      } else {
        await txn.update(
          'sales_documents',
          docMap,
          where: 'id = ?',
          whereArgs: [docToSave.id],
        );
        returnedDocId = docToSave.id!;
      }

      // Delete existing items and re-insert
      await txn.delete(
        'sales_document_items',
        where: 'document_id = ?',
        whereArgs: [returnedDocId],
      );

      for (final item in docToSave.items) {
        await txn.insert(
          'sales_document_items',
          SalesDocItemModel.toMap(item, returnedDocId),
        );
      }

      return docToSave.copyWith(
        id: returnedDocId,
        customer: doc.customer?.copyWith(id: customerId),
        supplier: doc.supplier?.copyWith(id: supplierId),
      );
    });
  }

  /// Confirm a document: validates stock (for delivery notes and invoices),
  /// logs transactions, updates DB.
  Future<SalesDocument> confirmDocument(SalesDocument doc) async {
    final db = await _dbHelper.database;

    return db.transaction((txn) async {
      final bool affectsStock =
          doc.docType == DocType.deliveryNote ||
          doc.docType == DocType.invoice ||
          doc.docType == DocType.materialReceipt;

      final bool isRestock = doc.docType == DocType.materialReceipt;

      if (affectsStock) {
        // 1. Check stock settings
        final settingRows = await txn.query(
          'settings',
          where: 'key = ?',
          whereArgs: [SettingsKeys.allowNegativeStock],
        );
        final allowNegative =
            settingRows.isNotEmpty && settingRows.first['value'] == 'true';

        // 2. Validate stock & decrement items
        for (final item in doc.items) {
          final productRows = await txn.query(
            'products',
            columns: ['quantity_on_hand'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (productRows.isEmpty) {
            throw ValidationFailure('Product ${item.sku} not found in DB.');
          }

          final currentQty = productRows.first['quantity_on_hand'] as double;
          final newQty = isRestock
              ? currentQty + item.quantity
              : currentQty - item.quantity;

          if (newQty < 0 && !allowNegative && !isRestock) {
            throw ValidationFailure(
              'Cannot sell ${item.quantity} of ${item.productName}. '
              'Only $currentQty in stock.',
            );
          }

          // Decrement product stock
          await txn.update(
            'products',
            {
              'quantity_on_hand': newQty,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          // Insert stock transaction history
          final stockTxn = StockTransaction(
            productId: item.productId,
            sku: item.sku,
            timestamp: DateTime.now(),
            changeAmount: isRestock ? item.quantity : -item.quantity,
            reason: isRestock
                ? TransactionReason.restock
                : TransactionReason.sale,
            resultingTotal: newQty,
            notes: '${doc.docType.label} ${doc.docNumber}',
          );
          await txn.insert('transactions', TransactionModel.toMap(stockTxn));
        }
      }

      // 3. Mark document as confirmed and save
      final confirmedDoc = doc.copyWith(status: DocStatus.confirmed);

      // Handle customer
      int? customerId = confirmedDoc.customerId;
      if (confirmedDoc.customer != null &&
          confirmedDoc.customer!.name != 'Cash customer') {
        final custMap = CustomerModel.toMap(confirmedDoc.customer!);
        if (confirmedDoc.customer!.id == null) {
          customerId = await txn.insert('customers', custMap);
        } else {
          await txn.update(
            'customers',
            custMap,
            where: 'id = ?',
            whereArgs: [confirmedDoc.customer!.id],
          );
          customerId = confirmedDoc.customer!.id;
        }
      } else if (confirmedDoc.customer?.name ==
          AppDefaults.defaultCustomerName) {
        customerId = null; // Do not save cash customer to DB
      }

      // Handle supplier
      int? supplierId = confirmedDoc.supplierId;
      if (confirmedDoc.supplier != null) {
        final suppMap = SupplierModel.toMap(confirmedDoc.supplier!);
        if (confirmedDoc.supplier!.id == null) {
          supplierId = await txn.insert('suppliers', suppMap);
        } else {
          await txn.update(
            'suppliers',
            suppMap,
            where: 'id = ?',
            whereArgs: [confirmedDoc.supplier!.id],
          );
          supplierId = confirmedDoc.supplier!.id;
        }
      }

      final docToSave = confirmedDoc.copyWith(
        customerId: customerId,
        supplierId: supplierId,
      );
      final docMap = SalesDocumentModel.toMap(docToSave);

      int returnedDocId;
      if (docToSave.id == null) {
        returnedDocId = await txn.insert('sales_documents', docMap);
      } else {
        await txn.update(
          'sales_documents',
          docMap,
          where: 'id = ?',
          whereArgs: [docToSave.id],
        );
        returnedDocId = docToSave.id!;
      }

      // 4. Save line items
      if (docToSave.id != null) {
        await txn.delete(
          'sales_document_items',
          where: 'document_id = ?',
          whereArgs: [returnedDocId],
        );
      }

      for (final item in docToSave.items) {
        await txn.insert(
          'sales_document_items',
          SalesDocItemModel.toMap(item, returnedDocId),
        );
      }

      // 5. Update source PO status for partial/full receipts
      if (docToSave.docType == DocType.materialReceipt &&
          docToSave.sourceDocId != null) {
        final poRows = await txn.query(
          'sales_documents',
          where: 'id = ? AND doc_type = ?',
          whereArgs: [docToSave.sourceDocId, DocType.purchaseOrder.value],
        );
        if (poRows.isNotEmpty) {
          final poId = docToSave.sourceDocId!;

          final poItemsRows = await txn.query(
            'sales_document_items',
            where: 'document_id = ?',
            whereArgs: [poId],
          );
          double totalPoQty = 0;
          for (final row in poItemsRows) {
            totalPoQty += (row['quantity'] as num).toDouble();
          }

          final mrRows = await txn.query(
            'sales_documents',
            columns: ['id'],
            where: 'source_doc_id = ? AND status = ?',
            whereArgs: [poId, DocStatus.confirmed.value],
          );

          double totalMrQty = 0;
          for (final mrRow in mrRows) {
            final mrId = mrRow['id'] as int;
            final mrItemsRows = await txn.query(
              'sales_document_items',
              where: 'document_id = ?',
              whereArgs: [mrId],
            );
            for (final row in mrItemsRows) {
              totalMrQty += (row['quantity'] as num).toDouble();
            }
          }

          // Also include the current MR being confirmed in the count,
          // since it might not be committed yet if we query mid-transaction.
          // Wait, 'mrRows' query will catch it if returnedDocId was already updated
          // above! Yes, returnedDocId was updated to 'confirmed' at line 456. So it's handled.

          final newPoStatus = totalMrQty >= totalPoQty
              ? DocStatus.received.value
              : DocStatus.partiallyReceived.value;

          await txn.update(
            'sales_documents',
            {'status': newPoStatus},
            where: 'id = ?',
            whereArgs: [poId],
          );
        }
      }

      return docToSave.copyWith(
        id: returnedDocId,
        customer: confirmedDoc.customer?.copyWith(id: customerId),
        supplier: confirmedDoc.supplier?.copyWith(id: supplierId),
        status: DocStatus.confirmed, // ensure UI updates to confirmed
      );
    });
  }

  /// Convert a document to a different type.
  Future<SalesDocument> convertDocument(
    int sourceDocId,
    DocType targetType,
  ) async {
    final sourceDoc = await getDocumentById(sourceDocId);
    final newDocNumber = await getNextDocNumber(targetType);

    final newDoc = SalesDocument(
      docType: targetType,
      docNumber: newDocNumber,
      customer: sourceDoc.customer,
      customerId: sourceDoc.customerId,
      supplier: sourceDoc.supplier,
      supplierId: sourceDoc.supplierId,
      // Clear item IDs so they are treated as new insertions in the new document
      items: sourceDoc.items.map((i) => i.copyWith(id: null)).toList(),
      subtotal: sourceDoc.subtotal,
      discountPercent: sourceDoc.discountPercent,
      discountAmount: sourceDoc.discountAmount,
      taxAmount: sourceDoc.taxAmount,
      grandTotal: sourceDoc.grandTotal,
      status: DocStatus.draft,
      sourceDocId: sourceDoc.id,
      sourceDocNumber: sourceDoc.docNumber,
      deliveryDate: targetType == DocType.deliveryNote ? DateTime.now() : null,
      notes: sourceDoc.notes,
      createdAt: DateTime.now(),
    );

    return saveDocument(newDoc);
  }

  // ─── Business Intelligence ───────────────────────────────────────

  Future<double> getRevenueToday() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(grand_total) as today_rev 
      FROM sales_documents 
      WHERE status = 'confirmed' 
        AND doc_type = 'invoice'
        AND date(created_at, 'localtime') = date('now', 'localtime')
    ''');
    final val = result.first['today_rev'];
    return val != null ? (val as num).toDouble() : 0.0;
  }

  /// Returns a map of productName -> quantitySold
  Future<Map<String, int>> getTopSellingItems({int limit = 5}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT si.product_name, SUM(si.quantity) as total_sold
      FROM sales_document_items si
      JOIN sales_documents s ON si.document_id = s.id
      WHERE s.status = 'confirmed' AND s.doc_type = 'invoice'
      GROUP BY si.product_name
      ORDER BY total_sold DESC
      LIMIT ?
    ''',
      [limit],
    );
    final map = <String, int>{};
    for (final row in result) {
      map[(row['product_name']) as String] = (row['total_sold'] as num).toInt();
    }
    return map;
  }
}
