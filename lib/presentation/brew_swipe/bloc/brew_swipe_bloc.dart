import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/domain/repositories/coffee_repository.dart';
import 'package:very_good_coffee/core/image_prefetch.dart';

part 'brew_swipe_event.dart';
part 'brew_swipe_state.dart';

class BrewSwipeBloc extends Bloc<BrewSwipeEvent, BrewSwipeState> {
  BrewSwipeBloc(this._repo) : super(const BrewSwipeState.initial()) {
    on<BrewSwipeStarted>(_onStarted);
    on<BrewSwipeSkipPressed>(_onSkip);
    on<BrewSwipeSavePressed>(_onSave);
    on<BrewSwipeRetryPressed>(_onRetry);
    on<_BrewSwipeRefillRequested>(_onRefill);
  }

  final CoffeeRepository _repo;

  static const _bufferTarget = 6;
  static const _refillAt = 3;

  Future<void> _onStarted(
    BrewSwipeStarted event,
    Emitter<BrewSwipeState> emit,
  ) async {
    emit(state.copyWith(status: BrewSwipeStatus.loading, error: null));

    try {
      // fill cache
      final batch = await _repo.fetchBatch(_bufferTarget);
      await warmCache(batch.map((e) => e.remoteUrl),
          maxConcurrent: 2, delayBetween: const Duration(milliseconds: 120));

      // load First image then buffer
      emit(state.copyWith(
        status: BrewSwipeStatus.ready,
        current: batch.first,
        buffer: batch.skip(1).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BrewSwipeStatus.error,
        error: 'Out of beans. Please try again.',
      ));
    }
  }

  Future<void> _advance(Emitter<BrewSwipeState> emit) async {
    if (state.buffer.isEmpty) {
      emit(state.copyWith(status: BrewSwipeStatus.loading));
      add(const _BrewSwipeRefillRequested());
      return;
    }
    final next = state.buffer.first;
    final remaining = List<CoffeeImage>.from(state.buffer.skip(1));

    emit(state.copyWith(
      status: BrewSwipeStatus.ready,
      current: next,
      buffer: remaining,
    ));

    // Fetch more images if running low
    if (remaining.length < _refillAt) {
      add(const _BrewSwipeRefillRequested());
    }
  }

  Future<void> _onSkip(
    BrewSwipeSkipPressed event,
    Emitter<BrewSwipeState> emit,
  ) async {
    await _advance(emit);
  }

  Future<void> _onSave(
    BrewSwipeSavePressed event,
    Emitter<BrewSwipeState> emit,
  ) async {
    final image = state.current;
    if (image != null) {
      unawaited(_repo.saveFavorite(image));
    }
    await _advance(emit);
  }

  Future<void> _onRefill(
    _BrewSwipeRefillRequested event,
    Emitter<BrewSwipeState> emit,
  ) async {
    if (state.isRefilling) return;
    emit(state.copyWith(isRefilling: true));

    try {
      final need = _bufferTarget - state.buffer.length;
      if (need > 0) {
        final batch = await _repo.fetchBatch(need);
        await warmCache(batch.map((e) => e.remoteUrl),
            maxConcurrent: 2, delayBetween: const Duration(milliseconds: 120));
        emit(state.copyWith(buffer: [...state.buffer, ...batch]));
      }
    } finally {
      emit(state.copyWith(isRefilling: false));
    }
  }

  Future<void> _onRetry(
    BrewSwipeRetryPressed event,
    Emitter<BrewSwipeState> emit,
  ) async {
    add(const BrewSwipeStarted());
  }
}
