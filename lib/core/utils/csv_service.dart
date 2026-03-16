/// CSV import/export service — runs heavy processing on an isolate.
library;

import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';

class CsvService {
  CsvService._();

  /// Normalised names of columns that map to built-in Product fields.
  /// Used to identify which CSV columns are "extra" / custom attributes.
  static const _knownColumns = <String>{
    'itemcode',
    'sku',
    'itemname',
    'name',
    'brand',
    'productgroup',
    'category',
    'description',
    'detaileddescription',
    'moredescription',
    'salesrate',
    'unitprice',
    'purchaserate',
    'wholesaleprice',
    'mrp',
    'profitpercentage',
    'minimumsalerate',
    'addinpartnumber1',
    'addinpartnumber2',
    'image',
    'otherlanguage',
    'quantityonhand',
    'quantity',
    'unitofmeasure',
    'lowstockthreshold',
    'locationaisle',
    'locationshelf',
    'locationbin',
  };

  // ─── Export ──────────────────────────────────────────────────────

  /// Convert a list of products to a CSV-formatted string.
  /// Custom attributes (metadata) are included as extra columns.
  static String exportToCsv(List<Product> products) {
    // Collect all unique metadata keys across every product.
    final metaKeys = <String>{};
    for (final p in products) {
      for (final m in p.metadata) {
        metaKeys.add(m.key);
      }
    }
    final sortedMetaKeys = metaKeys.toList()..sort();

    final headers = [
      'Item Code',
      'Item Name',
      'Brand',
      'Product Group',
      'Detailed Description',
      'Description',
      'Sales Rate',
      'Purchase Rate',
      'Wholesale Price',
      'MRP',
      'Profit Percentage',
      'Minimum Sale Rate',
      'Addin Part Number 1',
      'Addin Part Number 2',
      'Image',
      'Other Language',
      'Quantity on Hand',
      'Unit of Measure',
      'Low Stock Threshold',
      'Location Aisle',
      'Location Shelf',
      'Location Bin',
      ...sortedMetaKeys,
    ];

    final rows = <List<dynamic>>[headers];
    for (final p in products) {
      // Build a quick lookup for this product's metadata.
      final metaMap = {for (final m in p.metadata) m.key: m.value};
      rows.add([
        p.itemCode,
        p.itemName,
        p.brand,
        p.productGroup,
        p.detailedDescription,
        p.description,
        p.salesRate,
        p.purchaseRate,
        p.wholesalePrice,
        p.mrp,
        p.profitPercentage,
        p.minimumSaleRate,
        p.addinPartNumber1,
        p.addinPartNumber2,
        p.image,
        p.otherLanguage,
        p.quantityOnHand,
        p.unitOfMeasure.label,
        p.lowStockThreshold,
        p.locationAisle,
        p.locationShelf,
        p.locationBin,
        ...sortedMetaKeys.map((k) => metaMap[k] ?? ''),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ─── Import (async — runs on isolate) ────────────────────────────

  /// Parse a CSV string on a background isolate so the UI stays responsive.
  static Future<List<Product>> parseCsvAsync(String csvString) {
    return Isolate.run(() => parseCsv(csvString));
  }

  // ─── Import (sync — used inside isolate) ────────────────────────

  /// Parse a CSV string into a list of [Product] objects ready for upsert.
  ///
  /// Uses header-mapping so column order doesn't matter.
  /// Throws [FormatException] if required columns (`item_code`, `item_name`) are missing.
  static List<Product> parseCsv(String csvString) {
    // Normalise line endings — \r\n → \n, stray \r → \n.
    final normalised = csvString
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final rows = const CsvToListConverter().convert(normalised, eol: '\n');
    if (rows.isEmpty) return [];

    // Build header index map (normalised to lowercase, stripped).
    final rawHeaders = rows.first.map((h) => _normalise(h.toString())).toList();
    // Also keep the original (display-friendly) header names for metadata keys.
    final originalHeaders = rows.first.map((h) => h.toString().trim()).toList();

    final headerMap = <String, int>{};
    for (var i = 0; i < rawHeaders.length; i++) {
      // Skip empty/blank headers (trailing commas in the CSV).
      if (rawHeaders[i].isEmpty) continue;
      headerMap[rawHeaders[i]] = i;
    }

    // Identify extra columns that are not known product fields.
    final extraColumns = <int, String>{};
    for (final entry in headerMap.entries) {
      if (!_knownColumns.contains(entry.key)) {
        // Use the original (un-normalised) header as the metadata key.
        extraColumns[entry.value] = originalHeaders[entry.value];
      }
    }

    // Validate required columns (with backward compatibility)
    if (!headerMap.containsKey('itemcode') && !headerMap.containsKey('sku')) {
      throw const FormatException('CSV is missing the required "Item Code" column.');
    }
    if (!headerMap.containsKey('itemname') && !headerMap.containsKey('name')) {
      throw const FormatException('CSV is missing the required "Item Name" column.');
    }

    final products = <Product>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      // Build metadata from extra (unknown) columns.
      final metadata = <ProductMetadata>[];
      for (final entry in extraColumns.entries) {
        final colIdx = entry.key;
        final colName = entry.value;
        if (colIdx < row.length) {
          final val = row[colIdx].toString().trim();
          if (val.isNotEmpty) {
            metadata.add(ProductMetadata(key: colName, value: val));
          }
        }
      }

      products.add(
        Product(
          itemCode: _cell(row, headerMap, 'itemcode').isNotEmpty
              ? _cell(row, headerMap, 'itemcode')
              : _cell(row, headerMap, 'sku'),
          itemName: _cell(row, headerMap, 'itemname').isNotEmpty
              ? _cell(row, headerMap, 'itemname')
              : _cell(row, headerMap, 'name'),
          brand: _cell(row, headerMap, 'brand'),
          productGroup: _cell(row, headerMap, 'productgroup').isNotEmpty
              ? _cell(row, headerMap, 'productgroup')
              : _cell(row, headerMap, 'category'),
          detailedDescription: _cell(row, headerMap, 'detaileddescription').isNotEmpty
              ? _cell(row, headerMap, 'detaileddescription')
              : _cell(row, headerMap, 'moredescription'),
          description: _cell(row, headerMap, 'description'),
          salesRate:
              _numCell(row, headerMap, 'salesrate') ??
              _numCell(row, headerMap, 'unitprice') ??
              0.0,
          purchaseRate: _numCell(row, headerMap, 'purchaserate') ?? 0.0,
          wholesalePrice: _numCell(row, headerMap, 'wholesaleprice') ?? 0.0,
          mrp: _numCell(row, headerMap, 'mrp') ?? 0.0,
          profitPercentage: _numCell(row, headerMap, 'profitpercentage') ?? 0.0,
          minimumSaleRate: _numCell(row, headerMap, 'minimumsalerate') ?? 0.0,
          addinPartNumber1: _cell(row, headerMap, 'addinpartnumber1'),
          addinPartNumber2: _cell(row, headerMap, 'addinpartnumber2'),
          image: _cell(row, headerMap, 'image'),
          otherLanguage: _cell(row, headerMap, 'otherlanguage'),
          quantityOnHand:
              _numCell(row, headerMap, 'quantityonhand') ??
              _numCell(row, headerMap, 'quantity') ??
              0.0,
          unitOfMeasure: UnitOfMeasure.fromString(
            _cell(row, headerMap, 'unitofmeasure').isNotEmpty
                ? _cell(row, headerMap, 'unitofmeasure')
                : 'Pieces',
          ),
          lowStockThreshold:
              _numCell(row, headerMap, 'lowstockthreshold') ??
              10.0,
          locationAisle: _cell(row, headerMap, 'locationaisle'),
          locationShelf: _cell(row, headerMap, 'locationshelf'),
          locationBin: _cell(row, headerMap, 'locationbin'),
          metadata: metadata,
        ),
      );
    }

    return products;
  }

  // ─── Internal helpers ────────────────────────────────────────────

  static String _normalise(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s_]'), '');

  static String _cell(List<dynamic> row, Map<String, int> map, String key) {
    final idx = map[key];
    if (idx == null || idx >= row.length) return '';
    return row[idx].toString().trim();
  }

  static double? _numCell(List<dynamic> row, Map<String, int> map, String key) {
    final raw = _cell(row, map, key);
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }
}
