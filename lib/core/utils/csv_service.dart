/// CSV import/export service — runs heavy processing on an isolate.
library;

import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';

class CsvService {
  CsvService._();

  // ─── Export ──────────────────────────────────────────────────────

  /// Convert a list of products to a CSV-formatted string.
  static String exportToCsv(List<Product> products) {
    final headers = [
      'SKU',
      'Name',
      'Brand',
      'Category',
      'More Description',
      'Description',
      'Unit Price',
      'Quantity on Hand',
      'Unit of Measure',
      'Low Stock Threshold',
      'Location Aisle',
      'Location Shelf',
      'Location Bin',
    ];

    final rows = <List<dynamic>>[headers];
    for (final p in products) {
      rows.add([
        p.sku,
        p.name,
        p.brand,
        p.category,
        p.moreDescription,
        p.description,
        p.unitPrice,
        p.quantityOnHand,
        p.unitOfMeasure.label,
        p.lowStockThreshold,
        p.locationAisle,
        p.locationShelf,
        p.locationBin,
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
  /// Throws [FormatException] if required columns (`sku`, `name`) are missing.
  static List<Product> parseCsv(String csvString) {
    // Normalise line endings — \r\n → \n, stray \r → \n.
    final normalised = csvString
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final rows = const CsvToListConverter().convert(normalised, eol: '\n');
    if (rows.isEmpty) return [];

    // Build header index map (normalised to lowercase, stripped).
    final rawHeaders = rows.first.map((h) => _normalise(h.toString())).toList();
    final headerMap = <String, int>{};
    for (var i = 0; i < rawHeaders.length; i++) {
      // Skip empty/blank headers (trailing commas in the CSV).
      if (rawHeaders[i].isEmpty) continue;
      headerMap[rawHeaders[i]] = i;
    }

    // Validate required columns
    if (!headerMap.containsKey('sku')) {
      throw const FormatException('CSV is missing the required "SKU" column.');
    }
    if (!headerMap.containsKey('name')) {
      throw const FormatException('CSV is missing the required "Name" column.');
    }

    final products = <Product>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      products.add(
        Product(
          sku: _cell(row, headerMap, 'sku'),
          name: _cell(row, headerMap, 'name'),
          brand: _cell(row, headerMap, 'brand'),
          category: _cell(row, headerMap, 'category'),
          moreDescription: _cell(row, headerMap, 'more_description').isNotEmpty
              ? _cell(row, headerMap, 'more_description')
              : _cell(row, headerMap, 'moredescription'),
          description: _cell(row, headerMap, 'description'),
          unitPrice:
              _numCell(row, headerMap, 'unitprice') ??
              _numCell(row, headerMap, 'unit_price') ??
              0.0,
          quantityOnHand:
              _numCell(row, headerMap, 'quantityonhand') ??
              _numCell(row, headerMap, 'quantity_on_hand') ??
              _numCell(row, headerMap, 'quantity') ??
              0.0,
          unitOfMeasure: UnitOfMeasure.fromString(
            _cell(row, headerMap, 'unitofmeasure').isNotEmpty
                ? _cell(row, headerMap, 'unitofmeasure')
                : _cell(row, headerMap, 'unit_of_measure').isNotEmpty
                ? _cell(row, headerMap, 'unit_of_measure')
                : 'Pieces',
          ),
          lowStockThreshold:
              _numCell(row, headerMap, 'lowstockthreshold') ??
              _numCell(row, headerMap, 'low_stock_threshold') ??
              10.0,
          locationAisle: _cell(row, headerMap, 'locationaisle').isNotEmpty
              ? _cell(row, headerMap, 'locationaisle')
              : _cell(row, headerMap, 'location_aisle'),
          locationShelf: _cell(row, headerMap, 'locationshelf').isNotEmpty
              ? _cell(row, headerMap, 'locationshelf')
              : _cell(row, headerMap, 'location_shelf'),
          locationBin: _cell(row, headerMap, 'locationbin').isNotEmpty
              ? _cell(row, headerMap, 'locationbin')
              : _cell(row, headerMap, 'location_bin'),
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
