/// Dashboard BLoC — aggregation queries for the home screen.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

// ─── Events ────────────────────────────────────────────────────────

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

// ─── States ────────────────────────────────────────────────────────

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.totalInventoryValue,
    required this.lowStockCount,
    required this.totalProducts,
    required this.recentTransactions,
  });
  final double totalInventoryValue;
  final int lowStockCount;
  final int totalProducts;
  final List<StockTransaction> recentTransactions;

  @override
  List<Object?> get props => [
    totalInventoryValue,
    lowStockCount,
    totalProducts,
    recentTransactions,
  ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ──────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required InventoryRepository inventoryRepository,
    required TransactionRepository transactionRepository,
  }) : _inventoryRepo = inventoryRepository,
       _transactionRepo = transactionRepository,
       super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
  }

  final InventoryRepository _inventoryRepo;
  final TransactionRepository _transactionRepo;

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final results = await Future.wait([
        _inventoryRepo.getTotalInventoryValue(),
        _inventoryRepo.getLowStockCount(),
        _inventoryRepo.getProducts(),
        _transactionRepo.getRecentTransactions(limit: 10),
      ]);

      emit(
        DashboardLoaded(
          totalInventoryValue: results[0] as double,
          lowStockCount: results[1] as int,
          totalProducts: (results[2] as List).length,
          recentTransactions: results[3] as List<StockTransaction>,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
