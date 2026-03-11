/// Data model for Supplier — handles SQLite map conversions.
library;

import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';

class SupplierModel {
  SupplierModel._();

  static Map<String, dynamic> toMap(Supplier supplier) {
    final now = DateTime.now().toIso8601String();
    return {
      if (supplier.id != null) 'id': supplier.id,
      'name': supplier.name,
      'phone': supplier.phone,
      'email': supplier.email,
      'address': supplier.address,
      'created_at': supplier.createdAt?.toIso8601String() ?? now,
    };
  }

  static Supplier fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: (map['phone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
