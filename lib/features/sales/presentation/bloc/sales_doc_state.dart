/// States for the SalesDoc BLoC.
library;

import 'package:equatable/equatable.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';

sealed class SalesDocState extends Equatable {
  const SalesDocState();

  @override
  List<Object?> get props => [];
}

/// Initial state / no active building.
class SalesDocInitial extends SalesDocState {
  const SalesDocInitial();
}

/// Loading data.
class SalesDocLoading extends SalesDocState {
  const SalesDocLoading();
}

/// User is actively building a draft document.
class SalesDocBuilding extends SalesDocState {
  const SalesDocBuilding(this.activeDoc);
  final SalesDocument activeDoc;

  @override
  List<Object?> get props => [activeDoc];
}

/// Processing the save operation.
class SalesDocSaving extends SalesDocState {
  const SalesDocSaving(this.activeDoc);
  final SalesDocument activeDoc;

  @override
  List<Object?> get props => [activeDoc];
}

/// Successfully saved draft.
class SalesDocSaved extends SalesDocState {
  const SalesDocSaved(this.doc);
  final SalesDocument doc;

  @override
  List<Object?> get props => [doc];
}

/// Successfully confirmed document.
class SalesDocConfirmed extends SalesDocState {
  const SalesDocConfirmed(this.doc);
  final SalesDocument doc;

  @override
  List<Object?> get props => [doc];
}

/// Viewing a list of historical documents.
class SalesDocListLoaded extends SalesDocState {
  const SalesDocListLoaded(this.documents);
  final List<SalesDocument> documents;

  @override
  List<Object?> get props => [documents];
}

/// Error state.
class SalesDocError extends SalesDocState {
  const SalesDocError(this.message, {this.activeDoc});
  final String message;
  final SalesDocument? activeDoc;

  @override
  List<Object?> get props => [message, activeDoc];
}
