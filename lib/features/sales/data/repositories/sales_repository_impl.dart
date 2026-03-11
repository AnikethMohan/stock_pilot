/// Implementation of the Sales repository.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/sales/data/datasources/sales_local_datasource.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/sales/domain/repositories/sales_repository.dart';
import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl({required SalesLocalDataSource dataSource})
    : _dataSource = dataSource;

  final SalesLocalDataSource _dataSource;

  @override
  Future<List<Customer>> getCustomers({String? searchQuery}) {
    return _dataSource.getCustomers(searchQuery: searchQuery);
  }

  @override
  Future<Customer> saveCustomer(Customer customer) {
    return _dataSource.saveCustomer(customer);
  }

  @override
  Future<List<Supplier>> getSuppliers({String? searchQuery}) {
    return _dataSource.getSuppliers(searchQuery: searchQuery);
  }

  @override
  Future<Supplier> saveSupplier(Supplier supplier) {
    return _dataSource.saveSupplier(supplier);
  }

  @override
  Future<String> getNextDocNumber(DocType type) {
    return _dataSource.getNextDocNumber(type);
  }

  @override
  Future<List<SalesDocument>> getDocuments({
    DocType? typeFilter,
    int limit = 50,
    int offset = 0,
  }) {
    return _dataSource.getDocuments(
      typeFilter: typeFilter,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<SalesDocument> getDocumentById(int id) {
    return _dataSource.getDocumentById(id);
  }

  @override
  Future<SalesDocument> saveDocument(SalesDocument doc) {
    return _dataSource.saveDocument(doc);
  }

  @override
  Future<SalesDocument> confirmDocument(SalesDocument doc) {
    return _dataSource.confirmDocument(doc);
  }

  @override
  Future<SalesDocument> convertDocument(int sourceDocId, DocType targetType) {
    return _dataSource.convertDocument(sourceDocId, targetType);
  }

  @override
  Future<double> getRevenueToday() {
    return _dataSource.getRevenueToday();
  }

  @override
  Future<Map<String, int>> getTopSellingItems({int limit = 5}) {
    return _dataSource.getTopSellingItems(limit: limit);
  }
}
