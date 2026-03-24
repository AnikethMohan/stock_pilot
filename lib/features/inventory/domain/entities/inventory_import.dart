import 'package:equatable/equatable.dart';

class InventoryImport extends Equatable {
  final int? id;
  final String filename;
  final DateTime date;
  final int totalRows;

  const InventoryImport({
    this.id,
    required this.filename,
    required this.date,
    required this.totalRows,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'filename': filename,
      'date': date.toIso8601String(),
      'total_rows': totalRows,
    };
  }

  factory InventoryImport.fromMap(Map<String, dynamic> map) {
    return InventoryImport(
      id: map['id'] as int?,
      filename: map['filename'] as String,
      date: DateTime.parse(map['date'] as String),
      totalRows: map['total_rows'] as int,
    );
  }

  @override
  List<Object?> get props => [id, filename, date, totalRows];
}
