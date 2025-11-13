import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feature/model/api_response_model.dart';
import 'base_state.dart';

/// Utility class for common Bloc patterns and operations
class BlocUtils {
  /// Helper method to handle API response and emit appropriate states
  static void handleApiResponse<T>({
    required Emitter<DataState<T>> emit,
    required ApiResponse<T> response,
    String? successMessage,
    bool logResponse = true,
  }) {
    if (logResponse) {
      log('API Response - Success: ${response.success}, Message: ${response.message}');
    }

    if (response.success && response.data != null) {
      emit(DataSuccess<T>(
        response.data!,
        message: successMessage ?? response.message,
      ));
    } else {
      emit(DataError<T>(
        response.message,
        errorCode: response.success ? null : 'API_ERROR',
      ));
    }
  }

  /// Helper method to handle exceptions and emit error states
  static void handleException<T>({
    required Emitter<DataState<T>> emit,
    required dynamic exception,
    String? customMessage,
    bool logException = true,
  }) {
    final errorMessage = customMessage ?? 'An unexpected error occurred: ${exception.toString()}';
    
    if (logException) {
      log('Exception handled: $exception');
    }

    emit(DataError<T>(
      errorMessage,
      errorCode: 'EXCEPTION',
    ));
  }

  /// Helper method to safely emit loading state
  static void emitLoading<T>(Emitter<DataState<T>> emit) {
    emit(const DataLoading<T>());
  }

  /// Helper method to safely emit refreshing state
  static void emitRefreshing<T>(Emitter<DataState<T>> emit, T currentData) {
    emit(DataRefreshing<T>(currentData));
  }
}

/// Mixin for Blocs that need to handle common patterns
mixin BlocStateMixin<Event, State> on Bloc<Event, State> {
  /// Add event to log all events for debugging
  void logEvent(Event event) {
    log('${runtimeType}: Event added - ${event.toString()}');
  }

  /// Add transition logging for debugging
  @override
  void onTransition(Transition<Event, State> transition) {
    super.onTransition(transition);
    log('${runtimeType}: ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}');
  }

  /// Add error logging
  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    log('${runtimeType}: Error occurred - $error');
  }
}
