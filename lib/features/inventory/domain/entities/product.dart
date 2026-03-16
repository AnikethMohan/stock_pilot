/// Product entity — the domain representation of a product.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';

class Product extends Equatable {
  const Product({
    this.id,
    required this.itemCode,
    this.barcode = '',
    required this.itemName,
    this.brand = '',
    this.productGroup = '',
    this.detailedDescription = '',
    this.description = '',
    this.salesRate = 0.0,
    this.costPrice = 0.0,
    this.purchaseRate = 0.0,
    this.wholesalePrice = 0.0,
    this.mrp = 0.0,
    this.profitPercentage = 0.0,
    this.minimumSaleRate = 0.0,
    this.addinPartNumber1 = '',
    this.addinPartNumber2 = '',
    this.image = '',
    this.otherLanguage = '',
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
  final String itemCode;
  final String barcode;
  final String itemName;
  final String brand;
  final String? productGroup;
  final String description;
  final String? detailedDescription;
  final double salesRate;
  final double costPrice;
  final double purchaseRate;
  final double wholesalePrice;
  final double mrp;
  final double profitPercentage;
  final double minimumSaleRate;
  final String addinPartNumber1;
  final String addinPartNumber2;
  final String image;
  final String otherLanguage;
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
  double get totalValue => salesRate * quantityOnHand;

  Product copyWith({
    int? id,
    String? itemCode,
    String? barcode,
    String? itemName,
    String? brand,
    String? productGroup,
    String? detailedDescription,
    String? description,
    double? salesRate,
    double? costPrice,
    double? purchaseRate,
    double? wholesalePrice,
    double? mrp,
    double? profitPercentage,
    double? minimumSaleRate,
    String? addinPartNumber1,
    String? addinPartNumber2,
    String? image,
    String? otherLanguage,
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
      itemCode: itemCode ?? this.itemCode,
      barcode: barcode ?? this.barcode,
      itemName: itemName ?? this.itemName,
      brand: brand ?? this.brand,
      productGroup: productGroup ?? this.productGroup,
      description: description ?? this.description,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      salesRate: salesRate ?? this.salesRate,
      costPrice: costPrice ?? this.costPrice,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      mrp: mrp ?? this.mrp,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      minimumSaleRate: minimumSaleRate ?? this.minimumSaleRate,
      addinPartNumber1: addinPartNumber1 ?? this.addinPartNumber1,
      addinPartNumber2: addinPartNumber2 ?? this.addinPartNumber2,
      image: image ?? this.image,
      otherLanguage: otherLanguage ?? this.otherLanguage,
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
    itemCode,
    barcode,
    itemName,
    brand,
    productGroup,
    detailedDescription,
    description,
    salesRate,
    costPrice,
    purchaseRate,
    wholesalePrice,
    mrp,
    profitPercentage,
    minimumSaleRate,
    addinPartNumber1,
    addinPartNumber2,
    image,
    otherLanguage,
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
