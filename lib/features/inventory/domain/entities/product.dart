/// Product entity — the domain representation of a product.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';

class Product extends Equatable {
  const Product({
    this.id,
    required this.sku,
    required this.name,
    this.brand = '',
    this.category = '',
    this.moreDescription = '',
    this.description = '',
    this.unitPrice = 0.0,
    this.costPrice = 0.0,
    this.quantityOnHand = 0.0,
    this.unitOfMeasure = UnitOfMeasure.pieces,
    this.lowStockThreshold = 10.0,
    this.locationAisle = '',
    this.locationShelf = '',
    this.locationBin = '',
    this.createdAt,
    this.updatedAt,
    this.metadata = const [],
  });

  final int? id;
  final String sku;
  final String name;
  final String brand;
  final String category;
  final String description;
  final String moreDescription;
  final double unitPrice;
  final double costPrice;
  final double quantityOnHand;
  final UnitOfMeasure unitOfMeasure;
  final double lowStockThreshold;
  final String locationAisle;
  final String locationShelf;
  final String locationBin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProductMetadata> metadata;

  bool get isLowStock => quantityOnHand <= lowStockThreshold;
  double get totalValue => unitPrice * quantityOnHand;

  Product copyWith({
    int? id,
    String? sku,
    String? name,
    String? brand,
    String? category,
    String? moreDescription,
    String? description,
    double? unitPrice,
    double? costPrice,
    double? quantityOnHand,
    UnitOfMeasure? unitOfMeasure,
    double? lowStockThreshold,
    String? locationAisle,
    String? locationShelf,
    String? locationBin,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductMetadata>? metadata,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      description: description ?? this.description,
      moreDescription: moreDescription ?? this.moreDescription,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      locationAisle: locationAisle ?? this.locationAisle,
      locationShelf: locationShelf ?? this.locationShelf,
      locationBin: locationBin ?? this.locationBin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sku,
    name,
    brand,
    category,
    moreDescription,
    description,
    unitPrice,
    costPrice,
    quantityOnHand,
    unitOfMeasure,
    lowStockThreshold,
    locationAisle,
    locationShelf,
    locationBin,
    createdAt,
    updatedAt,
    metadata,
  ];
}

class ProductMetadata extends Equatable {
  const ProductMetadata({
    this.id,
    this.productId,
    required this.key,
    this.value = '',
  });

  final int? id;
  final int? productId;
  final String key;
  final String value;

  ProductMetadata copyWith({
    int? id,
    int? productId,
    String? key,
    String? value,
  }) {
    return ProductMetadata(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [id, productId, key, value];
}
