/// BLoC managing the state of sales document building and history.
library;

import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/sales/domain/repositories/sales_repository.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_event.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_state.dart';

class SalesDocBloc extends Bloc<SalesDocEvent, SalesDocState> {
  SalesDocBloc({required SalesRepository repository})
    : _repository = repository,
      super(const SalesDocInitial()) {
    on<StartNewDocument>(_onStartNewDocument);
    on<SetDocType>(_onSetDocType);
    on<AddDocItem>(_onAddDocItem);
    on<RemoveDocItem>(_onRemoveDocItem);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
    on<UpdateItemPrice>(_onUpdateItemPrice);
    on<UpdateItemDiscount>(_onUpdateItemDiscount);
    on<UpdateItemDiscountAmount>(_onUpdateItemDiscountAmount);
    on<UpdateItemTax>(_onUpdateItemTax);
    on<SelectCustomer>(_onSelectCustomer);
    on<SelectSupplier>(_onSelectSupplier);
    on<UpdateGlobalDiscount>(_onUpdateGlobalDiscount);
    on<UpdateGlobalDiscountAmount>(_onUpdateGlobalDiscountAmount);
    on<UpdateNotes>(_onUpdateNotes);
    on<SaveDraft>(_onSaveDraft);
    on<ConfirmDocument>(_onConfirmDocument);
    on<ConvertDocument>(_onConvertDocument);
    on<LoadDocuments>(_onLoadDocuments);
  }

  final SalesRepository _repository;

  Future<void> _onStartNewDocument(
    StartNewDocument event,
    Emitter<SalesDocState> emit,
  ) async {
    emit(const SalesDocLoading());
    try {
      if (event.existing != null) {
        emit(SalesDocBuilding(event.existing!));
      } else {
        final type = event.type ?? DocType.invoice;
        final number = await _repository.getNextDocNumber(type);
        final draft = SalesDocument(
          docType: type,
          docNumber: number,
          createdAt: DateTime.now(),
        );
        emit(SalesDocBuilding(draft));
      }
    } catch (e) {
      emit(SalesDocError(e.toString()));
    }
  }

  Future<void> _onSetDocType(
    SetDocType event,
    Emitter<SalesDocState> emit,
  ) async {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;
    try {
      final number = await _repository.getNextDocNumber(event.type);
      final updatedDoc = currentDoc.copyWith(
        docType: event.type,
        docNumber: number,
      );
      emit(SalesDocBuilding(updatedDoc));
    } catch (e) {
      emit(SalesDocError(e.toString(), activeDoc: currentDoc));
    }
  }

  void _onAddDocItem(AddDocItem event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    final existingIndex = currentDoc.items.indexWhere(
      (i) => i.itemCode == event.product.itemCode,
    );

    final updatedItems = List<SalesDocItem>.from(currentDoc.items);

    if (existingIndex >= 0) {
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + event.quantity,
      );
    } else {
      updatedItems.add(
        SalesDocItem.create(
          productId: event.product.id ?? 0,
          itemCode: event.product.itemCode,
          productName: event.product.itemName,
          salesRate: event.product.salesRate,
          quantity: event.quantity,
        ),
      );
    }

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onRemoveDocItem(RemoveDocItem event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    final updatedItems = currentDoc.items
        .where((i) => i.itemCode != event.itemCode)
        .toList();

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateItemQuantity(
    UpdateItemQuantity event,
    Emitter<SalesDocState> emit,
  ) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    if (event.quantity <= 0) {
      add(RemoveDocItem(itemCode: event.itemCode));
      return;
    }

    final updatedItems = currentDoc.items.map((item) {
      if (item.itemCode == event.itemCode) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateItemPrice(UpdateItemPrice event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    final updatedItems = currentDoc.items.map((item) {
      if (item.itemCode == event.itemCode) {
        return item.copyWith(salesRate: event.price);
      }
      return item;
    }).toList();

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateItemDiscount(
    UpdateItemDiscount event,
    Emitter<SalesDocState> emit,
  ) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    final updatedItems = currentDoc.items.map((item) {
      if (item.itemCode == event.itemCode) {
        return item.copyWith(discountPercent: event.discountPercent);
      }
      return item;
    }).toList();

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateItemDiscountAmount(
    UpdateItemDiscountAmount event,
    Emitter<SalesDocState> emit,
  ) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    final updatedItems = currentDoc.items.map((item) {
      if (item.itemCode == event.itemCode) {
        final gross = item.salesRate * item.quantity;
        final discPct = gross > 0 ? (event.discountAmount / gross) * 100 : 0.0;
        return item.copyWith(discountPercent: discPct);
      }
      return item;
    }).toList();

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateItemTax(UpdateItemTax event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;

    final updatedItems = currentDoc.items.map((item) {
      if (item.itemCode == event.itemCode) {
        return item.copyWith(taxPercent: event.taxPercent);
      }
      return item;
    }).toList();

    final updatedDoc = currentDoc.copyWith(items: updatedItems).recalculate();
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onSelectCustomer(SelectCustomer event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;
    final updatedDoc = currentDoc.copyWith(
      customer: event.customer,
      customerId: event.customer.id,
    );
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onSelectSupplier(SelectSupplier event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;
    final updatedDoc = currentDoc.copyWith(
      supplier: event.supplier,
      supplierId: event.supplier.id,
    );
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateGlobalDiscount(
    UpdateGlobalDiscount event,
    Emitter<SalesDocState> emit,
  ) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;
    final updatedDoc = currentDoc.recalculate(
      newGlobalDiscountPercent: event.discountPercent,
    );
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateGlobalDiscountAmount(
    UpdateGlobalDiscountAmount event,
    Emitter<SalesDocState> emit,
  ) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;
    final updatedDoc = currentDoc.recalculate(
      newGlobalDiscount: event.discountAmount,
    );
    emit(SalesDocBuilding(updatedDoc));
  }

  void _onUpdateNotes(UpdateNotes event, Emitter<SalesDocState> emit) {
    if (state is! SalesDocBuilding) return;
    final currentDoc = (state as SalesDocBuilding).activeDoc;
    emit(SalesDocBuilding(currentDoc.copyWith(notes: event.notes)));
  }

  Future<void> _onSaveDraft(
    SaveDraft event,
    Emitter<SalesDocState> emit,
  ) async {
    if (state is! SalesDocBuilding) return;
    final draft = (state as SalesDocBuilding).activeDoc;

    emit(SalesDocSaving(draft));

    try {
      final saved = await _repository.saveDocument(draft);
      emit(SalesDocSaved(saved));
    } catch (e) {
      emit(SalesDocError('Failed to save draft: $e', activeDoc: draft));
      emit(SalesDocBuilding(draft));
    }
  }

  Future<void> _onConfirmDocument(
    ConfirmDocument event,
    Emitter<SalesDocState> emit,
  ) async {
    if (state is! SalesDocBuilding) return;
    final draft = (state as SalesDocBuilding).activeDoc;

    if (draft.items.isEmpty) {
      emit(SalesDocError('Cannot confirm empty document.', activeDoc: draft));
      return;
    }

    emit(SalesDocSaving(draft));

    try {
      final confirmed = await _repository.confirmDocument(draft);
      emit(SalesDocConfirmed(confirmed));
    } catch (e) {
      String msg = 'Failed to confirm document';
      debugPrint('$e');
      if (e is ValidationFailure) {
        msg = e.message;
      }
      emit(SalesDocError(msg, activeDoc: draft));
      emit(SalesDocBuilding(draft));
    }
  }

  Future<void> _onConvertDocument(
    ConvertDocument event,
    Emitter<SalesDocState> emit,
  ) async {
    emit(const SalesDocLoading());
    try {
      final converted = await _repository.convertDocument(
        event.sourceDocId,
        event.targetType,
      );
      emit(SalesDocBuilding(converted));
    } catch (e) {
      log('$e');
      emit(SalesDocError('Failed to convert document: $e'));
    }
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<SalesDocState> emit,
  ) async {
    emit(const SalesDocLoading());
    try {
      final docs = await _repository.getDocuments(
        typeFilter: event.typeFilter,
        limit: event.limit,
        offset: event.offset,
      );
      emit(SalesDocListLoaded(docs));
    } catch (e) {
      emit(SalesDocError(e.toString()));
    }
  }
}
