/// Transaction BLoC — manages the audit trail listing.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

// ─── Events ────────────────────────────────────────────────────────

sealed class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  const LoadTransactions({this.productId, this.limit = 50, this.offset = 0});
  final int? productId;
  final int limit;
  final int offset;
  @override
  List<Object?> get props => [productId, limit, offset];
}

// ─── States ────────────────────────────────────────────────────────

sealed class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  const TransactionLoaded(this.transactions);
  final List<StockTransaction> transactions;
  @override
  List<Object?> get props => [transactions];
}

class TransactionError extends TransactionState {
  const TransactionError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ──────────────────────────────────────────────────────────

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({required TransactionRepository repository})
    : _repo = repository,
      super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
  }

  final TransactionRepository _repo;

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final txns = await _repo.getTransactions(
        productId: event.productId,
        limit: event.limit,
        offset: event.offset,
      );
      emit(TransactionLoaded(txns));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
