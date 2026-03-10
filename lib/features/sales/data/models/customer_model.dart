/// Data model for Customer — handles SQLite map conversions.
library;

import 'package:stock_pilot/features/sales/domain/entities/customer.dart';

class CustomerModel {
  CustomerModel._();

  static Map<String, dynamic> toMap(Customer customer) {
    final now = DateTime.now().toIso8601String();
    return {
      if (customer.id != null) 'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'email': customer.email,
      'address': customer.address,
      'created_at': customer.createdAt?.toIso8601String() ?? now,
    };
  }

  static Customer fromMap(Map<String, dynamic> map) {
    return Customer(
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
