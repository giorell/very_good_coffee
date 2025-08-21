part of 'brew_swipe_bloc.dart';

enum BrewSwipeStatus { initial, loading, ready, error }

class BrewSwipeState extends Equatable {
  const BrewSwipeState({
    required this.status,
    this.current,
    this.buffer = const [],
    this.isRefilling = false,
    this.error,
  });

  const BrewSwipeState.initial()
      : status = BrewSwipeStatus.initial,
        current = null,
        buffer = const [],
        isRefilling = false,
        error = null;

  final BrewSwipeStatus status;
  final CoffeeImage? current;

  final List<CoffeeImage> buffer;

  final bool isRefilling;

  final String? error;

  BrewSwipeState copyWith({
    BrewSwipeStatus? status,
    CoffeeImage? current,
    List<CoffeeImage>? buffer,
    bool? isRefilling,
    String? error,
  }) {
    return BrewSwipeState(
      status: status ?? this.status,
      current: current ?? this.current,
      buffer: buffer ?? this.buffer,
      isRefilling: isRefilling ?? this.isRefilling,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, current, buffer, isRefilling, error];
}
