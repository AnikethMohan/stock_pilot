/// Data model for StockTransaction — handles SQLite map conversions.
library;

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

class TransactionModel {
  TransactionModel._();

  static Map<String, dynamic> toMap(StockTransaction txn) {
    return {
      if (txn.id != null) 'id': txn.id,
      'product_id': txn.productId,
      'sku': txn.sku,
      'timestamp': txn.timestamp.toIso8601String(),
      'change_amount': txn.changeAmount,
      'reason': txn.reason.label,
      'resulting_total': txn.resultingTotal,
      'notes': txn.notes,
    };
  }

  static StockTransaction fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      changeAmount: (map['change_amount'] as num).toDouble(),
      reason: TransactionReason.fromString(map['reason'] as String),
      resultingTotal: (map['resulting_total'] as num).toDouble(),
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
