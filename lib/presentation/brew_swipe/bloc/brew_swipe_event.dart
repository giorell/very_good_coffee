part of 'brew_swipe_bloc.dart';

abstract class BrewSwipeEvent extends Equatable {
  const BrewSwipeEvent();

  @override
  List<Object?> get props => [];
}

class BrewSwipeStarted extends BrewSwipeEvent {
  const BrewSwipeStarted();
}

class BrewSwipeSkipPressed extends BrewSwipeEvent {
  const BrewSwipeSkipPressed();
}

class BrewSwipeSavePressed extends BrewSwipeEvent {
  const BrewSwipeSavePressed();
}

class BrewSwipeRetryPressed extends BrewSwipeEvent {
  const BrewSwipeRetryPressed();
}

class _BrewSwipeRefillRequested extends BrewSwipeEvent {
  const _BrewSwipeRefillRequested();
}
