/// Settings BLoC — manages app-level configuration toggles.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';

// ─── Events ────────────────────────────────────────────────────────

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class ToggleAllowNegativeStock extends SettingsEvent {
  const ToggleAllowNegativeStock(this.value);
  final bool value;
  @override
  List<Object?> get props => [value];
}

class UpdateDefaultThreshold extends SettingsEvent {
  const UpdateDefaultThreshold(this.value);
  final double value;
  @override
  List<Object?> get props => [value];
}

class UpdateDefaultCurrency extends SettingsEvent {
  const UpdateDefaultCurrency(this.currencyCode);
  final String currencyCode;
  @override
  List<Object?> get props => [currencyCode];
}

// ─── States ────────────────────────────────────────────────────────

sealed class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.allowNegativeStock,
    required this.defaultLowStockThreshold,
    required this.currencyCode,
    required this.currencySymbol,
  });
  final bool allowNegativeStock;
  final double defaultLowStockThreshold;
  final String currencyCode;
  final String currencySymbol;

  @override
  List<Object?> get props => [
    allowNegativeStock,
    defaultLowStockThreshold,
    currencyCode,
    currencySymbol,
  ];
}

class SettingsError extends SettingsState {
  const SettingsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ──────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepository repository})
    : _repo = repository,
      super(const SettingsInitial()) {
    on<LoadSettings>(_onLoad);
    on<ToggleAllowNegativeStock>(_onToggleNeg);
    on<UpdateDefaultThreshold>(_onUpdateThreshold);
    on<UpdateDefaultCurrency>(_onUpdateCurrency);
  }

  final SettingsRepository _repo;

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    try {
      final allowNeg = await _repo.getAllowNegativeStock();
      final threshold = await _repo.getDefaultLowStockThreshold();
      final code = await _repo.getDefaultCurrency();
      final currency = SupportedCurrency.fromCode(code);
      emit(
        SettingsLoaded(
          allowNegativeStock: allowNeg,
          defaultLowStockThreshold: threshold,
          currencyCode: currency.code,
          currencySymbol: currency.symbol,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onToggleNeg(
    ToggleAllowNegativeStock event,
    Emitter<SettingsState> emit,
  ) async {
    await _repo.setAllowNegativeStock(event.value);
    add(const LoadSettings());
  }

  Future<void> _onUpdateThreshold(
    UpdateDefaultThreshold event,
    Emitter<SettingsState> emit,
  ) async {
    await _repo.setDefaultLowStockThreshold(event.value);
    add(const LoadSettings());
  }

  Future<void> _onUpdateCurrency(
    UpdateDefaultCurrency event,
    Emitter<SettingsState> emit,
  ) async {
    await _repo.setDefaultCurrency(event.currencyCode);
    add(const LoadSettings());
  }
}
