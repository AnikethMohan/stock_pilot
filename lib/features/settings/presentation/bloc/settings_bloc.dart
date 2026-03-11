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

class UpdateBusinessInfo extends SettingsEvent {
  const UpdateBusinessInfo({
    this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
  });
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;

  @override
  List<Object?> get props => [name, address, phone, email, website];
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
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessWebsite = '',
  });
  final bool allowNegativeStock;
  final double defaultLowStockThreshold;
  final String currencyCode;
  final String currencySymbol;
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessWebsite;

  @override
  List<Object?> get props => [
    allowNegativeStock,
    defaultLowStockThreshold,
    currencyCode,
    currencySymbol,
    businessName,
    businessAddress,
    businessPhone,
    businessEmail,
    businessWebsite,
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
    on<UpdateBusinessInfo>(_onUpdateBusinessInfo);
  }

  final SettingsRepository _repo;

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    try {
      final allowNeg = await _repo.getAllowNegativeStock();
      final threshold = await _repo.getDefaultLowStockThreshold();
      final code = await _repo.getDefaultCurrency();
      final currency = SupportedCurrency.fromCode(code);

      final bName = await _repo.getBusinessName();
      final bAddress = await _repo.getBusinessAddress();
      final bPhone = await _repo.getBusinessPhone();
      final bEmail = await _repo.getBusinessEmail();
      final bWebsite = await _repo.getBusinessWebsite();

      emit(
        SettingsLoaded(
          allowNegativeStock: allowNeg,
          defaultLowStockThreshold: threshold,
          currencyCode: currency.code,
          currencySymbol: currency.symbol,
          businessName: bName,
          businessAddress: bAddress,
          businessPhone: bPhone,
          businessEmail: bEmail,
          businessWebsite: bWebsite,
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

  Future<void> _onUpdateBusinessInfo(
    UpdateBusinessInfo event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.name != null) await _repo.setBusinessName(event.name!);
    if (event.address != null) await _repo.setBusinessAddress(event.address!);
    if (event.phone != null) await _repo.setBusinessPhone(event.phone!);
    if (event.email != null) await _repo.setBusinessEmail(event.email!);
    if (event.website != null) await _repo.setBusinessWebsite(event.website!);
    add(const LoadSettings());
  }
}
