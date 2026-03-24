import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/features/inventory/domain/entities/inventory_import.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/stock_repository.dart';

// --- Events ---
abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

class StartImport extends ImportEvent {
  final String filename;
  final String content;

  const StartImport({required this.filename, required this.content});

  @override
  List<Object?> get props => [filename, content];
}

class ReverseImportEvent extends ImportEvent {
  final int importId;

  const ReverseImportEvent(this.importId);

  @override
  List<Object?> get props => [importId];
}

class LoadImportsEvent extends ImportEvent {}

// --- States ---
abstract class ImportState extends Equatable {
  const ImportState();

  @override
  List<Object?> get props => [];
}

class ImportInitial extends ImportState {}

class ImportProcessing extends ImportState {
  final String message;

  const ImportProcessing([this.message = 'Processing...']);

  @override
  List<Object?> get props => [message];
}

class ImportSuccess extends ImportState {
  final InventoryImport importRecord;

  const ImportSuccess(this.importRecord);

  @override
  List<Object?> get props => [importRecord];
}

class ImportReversing extends ImportState {
  final int importId;

  const ImportReversing(this.importId);

  @override
  List<Object?> get props => [importId];
}

class ImportReverseSuccess extends ImportState {
  final int importId;

  const ImportReverseSuccess(this.importId);

  @override
  List<Object?> get props => [importId];
}

class ImportError extends ImportState {
  final String message;

  const ImportError(this.message);

  @override
  List<Object?> get props => [message];
}

class ImportsLoaded extends ImportState {
  final List<InventoryImport> imports;

  const ImportsLoaded(this.imports);

  @override
  List<Object?> get props => [imports];
}

// --- Bloc ---
class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final StockRepository repository;

  ImportBloc({required this.repository}) : super(ImportInitial()) {
    on<StartImport>(_onStartImport);
    on<ReverseImportEvent>(_onReverseImport);
    on<LoadImportsEvent>(_onLoadImports);
  }

  Future<void> _onLoadImports(
    LoadImportsEvent event,
    Emitter<ImportState> emit,
  ) async {
    try {
      final imports = await repository.getImports();
      emit(ImportsLoaded(imports));
    } catch (e) {
      if (e is Failure) {
        emit(ImportError(e.message));
      } else {
        emit(ImportError('Failed to load imports: $e'));
      }
    }
  }

  Future<void> _onStartImport(
    StartImport event,
    Emitter<ImportState> emit,
  ) async {
    emit(const ImportProcessing('Reading and parsing CSV file...'));
    try {
      final importRecord = await repository.importCsvBulk(
        event.filename,
        event.content,
      );
      emit(ImportSuccess(importRecord));
    } catch (e) {
      if (e is Failure) {
        emit(ImportError(e.message));
      } else {
        emit(ImportError('Failed to import CSV: $e'));
      }
    }
  }

  Future<void> _onReverseImport(
    ReverseImportEvent event,
    Emitter<ImportState> emit,
  ) async {
    emit(ImportReversing(event.importId));
    try {
      await repository.reverseImport(event.importId);
      emit(ImportReverseSuccess(event.importId));
    } catch (e) {
      if (e is Failure) {
        emit(ImportError(e.message));
      } else {
        emit(ImportError('Failed to reverse import: $e'));
      }
    }
  }
}
