import 'package:equatable/equatable.dart';

/// Abstract base event class that all Bloc events should extend
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];
}

/// Common events that can be used across multiple Blocs
abstract class CommonEvent extends BaseEvent {
  const CommonEvent();
}

/// Event to refresh/reload data
class RefreshRequested extends CommonEvent {
  const RefreshRequested();
}

/// Event to reset state
class ResetRequested extends CommonEvent {
  const ResetRequested();
}

/// Event to clear error
class ErrorCleared extends CommonEvent {
  const ErrorCleared();
}
