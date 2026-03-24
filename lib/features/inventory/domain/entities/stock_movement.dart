import 'package:equatable/equatable.dart';

class StockMovement extends Equatable {
  final int? id;
  final int productId;
  final double quantityDelta;
  final String movementType;
  final String? referenceId;
  final DateTime timestamp;
  final String? notes;

  const StockMovement({
    this.id,
    required this.productId,
    required this.quantityDelta,
    required this.movementType,
    this.referenceId,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'quantity_delta': quantityDelta,
      'movement_type': movementType,
      'reference_id': referenceId,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantityDelta: (map['quantity_delta'] as num).toDouble(),
      movementType: map['movement_type'] as String,
      referenceId: map['reference_id'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        quantityDelta,
        movementType,
        referenceId,
        timestamp,
        notes,
      ];
}
