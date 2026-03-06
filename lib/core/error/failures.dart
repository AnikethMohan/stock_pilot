/// Failure types for the Stock Pilot application.
library;

import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A database error occurred.']);
}

class CsvFailure extends Failure {
  const CsvFailure([super.message = 'A CSV processing error occurred.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.']);
}

class NegativeStockFailure extends Failure {
  const NegativeStockFailure()
    : super(
        'Stock cannot go below zero. Enable "Allow Negative Stock" in Settings.',
      );
}
