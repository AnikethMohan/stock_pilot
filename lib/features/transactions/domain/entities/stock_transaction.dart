/// Stock transaction entity — represents a single inventory movement.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';

class StockTransaction extends Equatable {
  const StockTransaction({
    this.id,
    required this.productId,
    required this.sku,
    required this.timestamp,
    required this.changeAmount,
    required this.reason,
    required this.resultingTotal,
    this.notes = '',
  });

  final int? id;
  final int productId;
  final String sku;
  final DateTime timestamp;
  final double changeAmount;
  final TransactionReason reason;
  final double resultingTotal;
  final String notes;

  @override
  List<Object?> get props => [
    id,
    productId,
    sku,
    timestamp,
    changeAmount,
    reason,
    resultingTotal,
    notes,
  ];
}
