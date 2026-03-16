/// Data model for Product — handles SQLite map conversions.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';

class ProductModel {
  ProductModel._();

  static Map<String, dynamic> toMap(Product product) {
    final now = DateTime.now().toIso8601String();
    return {
      if (product.id != null) 'id': product.id,
      'item_code': product.itemCode,
      'barcode': product.barcode,
      'item_name': product.itemName,
      'brand': product.brand,
      'product_group': product.productGroup,
      'detailed_description': product.detailedDescription,
      'description': product.description,
      'sales_rate': product.salesRate,
      'cost_price': product.costPrice,
      'purchase_rate': product.purchaseRate,
      'wholesale_price': product.wholesalePrice,
      'mrp': product.mrp,
      'profit_percentage': product.profitPercentage,
      'minimum_sale_rate': product.minimumSaleRate,
      'addin_part_number_1': product.addinPartNumber1,
      'addin_part_number_2': product.addinPartNumber2,
      'image': product.image,
      'other_language': product.otherLanguage,
      'quantity_on_hand': product.quantityOnHand,
      'unit_of_measure': product.unitOfMeasure.label,
      'low_stock_threshold': product.lowStockThreshold,
      'location_aisle': product.locationAisle,
      'location_shelf': product.locationShelf,
      'location_bin': product.locationBin,
      'created_at': product.createdAt?.toIso8601String() ?? now,
      'updated_at': product.updatedAt?.toIso8601String() ?? now,
    };
  }

  static Product fromMap(
    Map<String, dynamic> map, {
    List<ProductMetadata> metadata = const [],
  }) {
    return Product(
      id: map['id'] as int?,
      itemCode: (map['item_code'] ?? map['sku']) as String,
      barcode: (map['barcode'] as String?) ?? '',
      itemName: (map['item_name'] ?? map['name']) as String,
      brand: (map['brand'] as String?) ?? '',
      productGroup: (map['product_group'] ?? map['category']) as String?,
      detailedDescription:
          (map['detailed_description'] ?? map['more_description']) as String?,
      description: (map['description'] as String?) ?? '',
      salesRate:
          (map['sales_rate'] ?? map['unit_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      purchaseRate: (map['purchase_rate'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      profitPercentage: (map['profit_percentage'] as num?)?.toDouble() ?? 0.0,
      minimumSaleRate: (map['minimum_sale_rate'] as num?)?.toDouble() ?? 0.0,
      addinPartNumber1: (map['addin_part_number_1'] as String?) ?? '',
      addinPartNumber2: (map['addin_part_number_2'] as String?) ?? '',
      image: (map['image'] as String?) ?? '',
      otherLanguage: (map['other_language'] as String?) ?? '',
      quantityOnHand: (map['quantity_on_hand'] as num?)?.toDouble() ?? 0.0,
      unitOfMeasure: UnitOfMeasure.fromString(
        (map['unit_of_measure'] as String?) ?? 'Pieces',
      ),
      lowStockThreshold:
          (map['low_stock_threshold'] as num?)?.toDouble() ?? 10.0,
      locationAisle: (map['location_aisle'] as String?) ?? '',
      locationShelf: (map['location_shelf'] as String?) ?? '',
      locationBin: (map['location_bin'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      metadata: metadata,
    );
  }
}

class MetadataModel {
  MetadataModel._();

  static Map<String, dynamic> toMap(ProductMetadata meta, int productId) {
    return {
      if (meta.id != null) 'id': meta.id,
      'product_id': productId,
      'key': meta.key,
      'value': meta.value,
    };
  }

  static ProductMetadata fromMap(Map<String, dynamic> map) {
    return ProductMetadata(
      id: map['id'] as int?,
      productId: map['product_id'] as int?,
      key: map['key'] as String,
      value: (map['value'] as String?) ?? '',
    );
  }
}
