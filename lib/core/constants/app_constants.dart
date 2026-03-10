/// Application-wide constants for Stock Pilot IMS.
library;

/// Units of measure supported by the inventory system.
enum UnitOfMeasure {
  pieces('Pieces'),
  kg('Kg'),
  liters('Liters'),
  meters('Meters'),
  boxes('Boxes'),
  packs('Packs'),
  units('Units');

  const UnitOfMeasure(this.label);
  final String label;

  static UnitOfMeasure fromString(String value) {
    return UnitOfMeasure.values.firstWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => UnitOfMeasure.pieces,
    );
  }
}

/// Reasons for inventory transactions.
enum TransactionReason {
  sale('Sale'),
  restock('Restock'),
  damage('Damage'),
  correction('Correction'),
  csvImport('CSV Import');

  const TransactionReason(this.label);
  final String label;

  static TransactionReason fromString(String value) {
    return TransactionReason.values.firstWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionReason.correction,
    );
  }
}

/// Document types for sales documents.
enum DocType {
  quotation('quotation', 'QUO'),
  deliveryNote('delivery_note', 'DN'),
  invoice('invoice', 'INV');

  const DocType(this.value, this.prefix);
  final String value;
  final String prefix;

  String get label => switch (this) {
    DocType.quotation => 'Quotation',
    DocType.deliveryNote => 'Delivery Note',
    DocType.invoice => 'Invoice',
  };

  static DocType fromString(String value) {
    return DocType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocType.invoice,
    );
  }
}

/// Statuses for sales documents.
enum DocStatus {
  draft('draft'),
  confirmed('confirmed'),
  cancelled('cancelled');

  const DocStatus(this.value);
  final String value;

  String get label => switch (this) {
    DocStatus.draft => 'Draft',
    DocStatus.confirmed => 'Confirmed',
    DocStatus.cancelled => 'Cancelled',
  };

  static DocStatus fromString(String value) {
    return DocStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocStatus.draft,
    );
  }
}

/// Default application settings.
class AppDefaults {
  AppDefaults._();

  static const double defaultLowStockThreshold = 10.0;
  static const bool defaultAllowNegativeStock = false;
  static const String dbName = 'stock_pilot.db';
  static const int dbVersion = 3;
  static const String defaultCurrencyCode = 'USD';
}

/// Settings keys used in the settings table.
class SettingsKeys {
  SettingsKeys._();

  static const String allowNegativeStock = 'allow_negative_stock';
  static const String defaultLowStockThreshold = 'default_low_stock_threshold';
  static const String defaultCurrency = 'default_currency';
}

/// A supported currency with its ISO code, symbol, and display name.
class SupportedCurrency {
  const SupportedCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;

  /// All supported currencies.
  /// All supported currencies.
  static const List<SupportedCurrency> all = [
    SupportedCurrency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    SupportedCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    SupportedCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
    SupportedCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    SupportedCurrency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    SupportedCurrency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    SupportedCurrency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    SupportedCurrency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    SupportedCurrency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
    SupportedCurrency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    SupportedCurrency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    SupportedCurrency(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso'),
    SupportedCurrency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    SupportedCurrency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    SupportedCurrency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),

    // Middle East
    SupportedCurrency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    SupportedCurrency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    SupportedCurrency(code: 'QAR', symbol: '﷼', name: 'Qatari Riyal'),
    SupportedCurrency(code: 'OMR', symbol: '﷼', name: 'Omani Riyal'),
    SupportedCurrency(code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar'),
    SupportedCurrency(code: 'BHD', symbol: '.د.ب', name: 'Bahraini Dinar'),
    SupportedCurrency(code: 'JOD', symbol: 'JD', name: 'Jordanian Dinar'),

    // Asia
    SupportedCurrency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    SupportedCurrency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    SupportedCurrency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
    SupportedCurrency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    SupportedCurrency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    SupportedCurrency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    SupportedCurrency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
  ];

  /// Look up a currency by its ISO code, defaulting to USD.
  static SupportedCurrency fromCode(String code) {
    return all.firstWhere((c) => c.code == code, orElse: () => all.first);
  }
}
