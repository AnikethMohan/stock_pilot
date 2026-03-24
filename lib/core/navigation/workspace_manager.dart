import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- Models ---

class WorkspaceItem extends Equatable {
  final String id;
  final String title;
  final IconData? icon;
  final Widget page;

  const WorkspaceItem({
    required this.id,
    required this.title,
    this.icon,
    required this.page,
  });

  @override
  List<Object?> get props => [id, title, icon, page];
}

// --- Events ---

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class WorkspaceItemOpened extends WorkspaceEvent {
  final WorkspaceItem item;
  final bool replaceCurrent;

  const WorkspaceItemOpened(this.item, {this.replaceCurrent = false});

  @override
  List<Object?> get props => [item, replaceCurrent];
}

class WorkspaceItemClosed extends WorkspaceEvent {
  final String id;

  const WorkspaceItemClosed(this.id);

  @override
  List<Object?> get props => [id];
}

class WorkspaceItemFocused extends WorkspaceEvent {
  final int index;

  const WorkspaceItemFocused(this.index);

  @override
  List<Object?> get props => [index];
}

class WorkspaceItemsReordered extends WorkspaceEvent {
  final int oldIndex;
  final int newIndex;

  const WorkspaceItemsReordered(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

// --- State ---

class WorkspaceState extends Equatable {
  final List<WorkspaceItem> items;
  final int activeIndex;

  const WorkspaceState({
    this.items = const [],
    this.activeIndex = 0,
  });

  WorkspaceItem? get activeItem =>
      items.isNotEmpty && activeIndex >= 0 && activeIndex < items.length
          ? items[activeIndex]
          : null;

  WorkspaceState copyWith({
    List<WorkspaceItem>? items,
    int? activeIndex,
  }) {
    return WorkspaceState(
      items: items ?? this.items,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  @override
  List<Object?> get props => [items, activeIndex];
}

// --- BLoC ---

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  static const int maxTabs = 10;

  WorkspaceBloc() : super(const WorkspaceState()) {
    on<WorkspaceItemOpened>(_onItemOpened);
    on<WorkspaceItemClosed>(_onItemClosed);
    on<WorkspaceItemFocused>(_onItemFocused);
    on<WorkspaceItemsReordered>(_onItemsReordered);
  }

  void _onItemOpened(WorkspaceItemOpened event, Emitter<WorkspaceState> emit) {
    var newItems = List<WorkspaceItem>.from(state.items);
    var newIndex = state.activeIndex;

    if (newItems.isEmpty) {
      newItems.add(event.item);
      newIndex = 0;
    } else {
      if (event.replaceCurrent) {
        newItems[newIndex] = event.item;
      } else {
        // Enforce max tabs
        if (newItems.length >= maxTabs) {
          // If we reached max tabs, we can optionally notify the user, 
          // or just ignore the open. For now, let's just replace the current one
          // or not add it. It's safer to just return or replace. Let's not add.
          // Or we can replace the current active one instead of appending.
          // Let's drop the request if maxed out and trying to append, 
          // but usually it's better to show a warning. Since we don't have a UI for warning here,
          // we'll just not add it, or replace the oldest?
          // Let's just return to not exceed the limit.
          return;
        }

        // Just append to the end.
        newItems.add(event.item);
        newIndex = newItems.length - 1;
      }
    }

    emit(state.copyWith(items: newItems, activeIndex: newIndex));
  }

  void _onItemClosed(WorkspaceItemClosed event, Emitter<WorkspaceState> emit) {
    final indexToRemove = state.items.indexWhere((item) => item.id == event.id);
    if (indexToRemove == -1) return;

    final newItems = List<WorkspaceItem>.from(state.items);
    newItems.removeAt(indexToRemove);

    if (newItems.isEmpty) {
      emit(state.copyWith(items: newItems, activeIndex: 0));
      return;
    }

    var newIndex = state.activeIndex;
    if (indexToRemove < newIndex) {
      newIndex--;
    } else if (indexToRemove == newIndex) {
      // If we closed the active tab, switch to the previous one (if any) or the next one
      if (newIndex >= newItems.length) {
        newIndex = newItems.length - 1;
      }
    }

    emit(state.copyWith(items: newItems, activeIndex: newIndex));
  }

  void _onItemFocused(WorkspaceItemFocused event, Emitter<WorkspaceState> emit) {
    if (event.index >= 0 && event.index < state.items.length) {
      emit(state.copyWith(activeIndex: event.index));
    }
  }

  void _onItemsReordered(
      WorkspaceItemsReordered event, Emitter<WorkspaceState> emit) {
    if (event.oldIndex == event.newIndex) return;
    
    final newItems = List<WorkspaceItem>.from(state.items);
    
    var adjustedNewIndex = event.newIndex;
    if (event.oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }
    
    final item = newItems.removeAt(event.oldIndex);
    newItems.insert(adjustedNewIndex, item);
    
    // Adjust active index
    var newActiveIndex = state.activeIndex;
    if (state.activeIndex == event.oldIndex) {
      newActiveIndex = adjustedNewIndex;
    } else {
      if (state.activeIndex > event.oldIndex && state.activeIndex <= adjustedNewIndex) {
        newActiveIndex--;
      } else if (state.activeIndex < event.oldIndex && state.activeIndex >= adjustedNewIndex) {
        newActiveIndex++;
      }
    }

    emit(state.copyWith(items: newItems, activeIndex: newActiveIndex));
  }
}
