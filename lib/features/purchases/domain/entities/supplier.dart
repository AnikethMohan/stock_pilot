/// Supplier entity — represents a vendor/seller.
library;

import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  const Supplier({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.createdAt,
  });

  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final DateTime? createdAt;

  Supplier copyWith({
    Object? id = const Object(),
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id == const Object() ? this.id : id as int?,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, email, address, createdAt];
}
