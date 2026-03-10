/// Sales repository interface — defines domain operations.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';

abstract class SalesRepository {
  // ─── Customers ─────────────────────────────
  Future<List<Customer>> getCustomers({String? searchQuery});
  Future<Customer> saveCustomer(Customer customer);

  // ─── Sales Documents ───────────────────────
  Future<String> getNextDocNumber(DocType type);
  Future<List<SalesDocument>> getDocuments({
    DocType? typeFilter,
    int limit = 50,
    int offset = 0,
  });
  Future<SalesDocument> getDocumentById(int id);
  Future<SalesDocument> saveDocument(SalesDocument doc);
  Future<SalesDocument> confirmDocument(SalesDocument doc);
  Future<SalesDocument> convertDocument(int sourceDocId, DocType targetType);

  // ─── Business Intelligence ───
  Future<double> getRevenueToday();
  Future<Map<String, int>> getTopSellingItems({int limit = 5});
}
