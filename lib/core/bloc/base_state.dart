import 'package:equatable/equatable.dart';

/// Abstract base state class that all Bloc states should extend
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Generic data state for handling loading, success, and error states
abstract class DataState<T> extends BaseState {
  const DataState();
}

/// Initial state
class DataInitial<T> extends DataState<T> {
  const DataInitial();
}

/// Loading state
class DataLoading<T> extends DataState<T> {
  const DataLoading();
}

/// Success state with data
class DataSuccess<T> extends DataState<T> {
  final T data;
  final String? message;

  const DataSuccess(this.data, {this.message});

  @override
  List<Object?> get props => [data, message];
}

/// Error state
class DataError<T> extends DataState<T> {
  final String message;
  final String? errorCode;

  const DataError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Loading with existing data (for refresh scenarios)
class DataRefreshing<T> extends DataState<T> {
  final T currentData;

  const DataRefreshing(this.currentData);

  @override
  List<Object?> get props => [currentData];
}
