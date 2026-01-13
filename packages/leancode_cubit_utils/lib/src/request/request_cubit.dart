import 'dart:async';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit_config.dart';
import 'package:logging/logging.dart';

/// Signature for a function that performs a request.
typedef Request<TRes> = Future<TRes> Function();

/// Signature for a function that performs a request with given arguments.
typedef ArgsRequest<TArgs, TRes> = Future<TRes> Function(TArgs);

/// Signature for a function that maps request response of to the output type.
typedef ResponseMapper<TRes, TOut> = TOut Function(TRes);

/// Signature for a function that checks if the request response is empty.
typedef EmptyChecker<TRes> = bool Function(TRes);

/// Signature for a function that maps request error to other state.
typedef ErrorMapper<TOut, TError> =
    Future<TOut> Function(RequestErrorState<TOut, TError>);

/// Defines how to handle a new request when the previous one is still running.
enum RequestMode {
  /// When a new request is triggered while the previous one is still running,
  /// the previous request is cancelled and the new one is executed.
  replace,

  /// When a new request is triggered while the previous one is still running,
  /// the new request is ignored.
  ignore,
}

/// Base class for all request cubits.
abstract class BaseRequestCubit<TRes, TOut, TError>
    extends Cubit<RequestState<TOut, TError>> {
  /// Creates a new [BaseRequestCubit] with the given [loggerTag] and [requestMode].
  BaseRequestCubit(String loggerTag, {this.requestMode})
    : logger = Logger(loggerTag),
      super(RequestInitialState());

  /// The logger used by this cubit.
  final Logger logger;

  /// Handles the given [result] and returns the corresponding state.
  Future<RequestState<TOut, TError>> handleResult(TRes result);

  /// The request mode used by this cubit to handle duplicated requests.
  final RequestMode? requestMode;

  CancelableOperation<TRes>? _operation;

  Future<void> _run(
    Future<TRes> Function() callback, {
    bool isRefresh = false,
  }) async {
    try {
      switch (requestMode ?? RequestCubitConfig.requestMode) {
        case RequestMode.replace:
          await _operation?.cancel();
        case RequestMode.ignore:
          if (_operation?.isCompleted == false) {
            logger.info('Previous operation is not completed. Ignoring.');
            return;
          }
      }

      if (state
          case RequestSuccessState(:final data) ||
              RequestRefreshState(:final data) when isRefresh) {
        logger.info('Refreshing request.');
        emit(RequestRefreshState(data: data));
      } else {
        logger.info('Request started.');
        emit(RequestLoadingState());
      }

      _operation = CancelableOperation.fromFuture(
        callback(),
        onCancel: () {
          logger.info('Canceling previous operation.');
        },
      );

      final result = await _operation?.valueOrCancellation();
      if (result == null) {
        return;
      }

      emit(await handleResult(result));
    } catch (e, s) {
      logger.severe('Request error. Exception: $e. Stack trace: $s');
      try {
        emit(await handleError(RequestErrorState(exception: e, stackTrace: s)));
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(RequestErrorState<TOut, TError>(exception: e, stackTrace: s));
      }
    }
  }

  /// Handles the given [errorState] and returns the corresponding state.
  Future<RequestErrorState<TOut, TError>> handleError(
    RequestErrorState<TOut, TError> errorState,
  ) async {
    return errorState;
  }

  /// Refreshes the request. Handling duplicated requests depends on the
  /// [requestMode].
  Future<void> refresh();
}

/// Base class for all request cubits which don't require any arguments.
abstract class RequestCubit<TRes, TOut, TError>
    extends BaseRequestCubit<TRes, TOut, TError> {
  /// Creates a new [RequestCubit] with the given [requestMode].
  RequestCubit(super.loggerTag, {super.requestMode});

  /// Gets the data from the request and emits the corresponding state.
  Future<void> run() => _run(request);

  /// A request to be executed.
  Future<TRes> request();

  /// Refreshes the request.
  @override
  Future<void> refresh() {
    return _run(request, isRefresh: true);
  }
}

/// Base class for all request cubits which require arguments.
abstract class ArgsRequestCubit<TArgs, TRes, TOut, TError>
    extends BaseRequestCubit<TRes, TOut, TError> {
  /// Creates a new [ArgsRequestCubit] with the given [requestMode].
  ArgsRequestCubit(super.loggerTag, {super.requestMode});

  TArgs? _lastRequestArgs;

  /// The arguments used by this cubit to refresh the request.
  TArgs? get lastRequestArgs => _lastRequestArgs;

  /// Gets the data from the request and emits the corresponding state.
  Future<void> run(TArgs args) {
    _lastRequestArgs = args;
    return _run(() => request(args));
  }

  /// A request to be executed.
  Future<TRes> request(TArgs args);

  @override
  Future<void> refresh() {
    if (_lastRequestArgs case final lastRequestArgs?) {
      return _run(() => request(lastRequestArgs), isRefresh: true);
    } else {
      logger.severe('No request was executed yet. Cannot refresh.');
      throw StateError('No request was executed yet. Cannot refresh.');
    }
  }
}

/// Represents the state of a request.
sealed class RequestState<TOut, TError> with EquatableMixin {
  /// Maps the current request state to a value of type [T].
  ///
  /// * [initial] - creates a [T] value when the request is in
  ///   its initial state (not yet started). **If not provided, falls back to
  ///   [loading]**.
  /// * [loading] - creates a [T] value when the request is loading.
  /// * [success] - creates a [T] value when the request completed
  ///   successfully with data. Data can be null in case of empty
  ///   state.
  /// * [error] - creates a [T] value when the request failed with an error.
  /// * [refreshing] - creates a [T] value when the request is refreshing with
  ///   previous data still available. **If not provided, falls back to
  ///   [success].**
  /// * [empty] - creates a [T] value when the request completed successfully
  ///   but returned empty data. **If not provided, falls back to [success].**
  ///
  /// ## Example
  ///
  /// ```dart
  /// Scaffold(
  ///   appBar: state.map<AppBar>(
  ///     onLoading: () => const LoadingAppBar(),
  ///     onSuccess: (data) => SuccessAppBar(data: data),
  ///     onError: (err, exception, st) => const ErrorAppBar(error: err),
  ///   ),
  /// );
  /// ```
  T map<T>({
    T Function()? initial,
    required T Function() loading,
    required T Function(TOut data) success,
    required T Function(TError? err, Object? exception, StackTrace? st) error,
    T Function(TOut data)? refreshing,
    T Function(TOut data)? empty,
  }) => switch (this) {
    RequestInitialState() => (initial ?? loading)(),
    RequestLoadingState() => loading(),
    RequestSuccessState(:final data) => success(data),
    RequestErrorState(error: final err, :final exception, :final stackTrace) =>
      error(err, exception, stackTrace),
    RequestRefreshState(:final data) => (refreshing ?? success)(data),
    RequestEmptyState(:final data) => (empty ?? success)(data),
  };
}

/// Represents the initial state of a request.
final class RequestInitialState<TOut, TError>
    extends RequestState<TOut, TError> {
  @override
  List<Object?> get props => [];
}

/// Represents the loading state of a request.
final class RequestLoadingState<TOut, TError>
    extends RequestState<TOut, TError> {
  /// Creates a new [RequestLoadingState].
  RequestLoadingState();

  @override
  List<Object?> get props => [];
}

/// Represents the refresh state of a request.
final class RequestRefreshState<TOut, TError>
    extends RequestState<TOut, TError> {
  /// Creates a new [RequestRefreshState] with the previous [data].
  RequestRefreshState({required this.data});

  /// The previous data.
  final TOut data;

  @override
  List<Object?> get props => [data];
}

/// Represents a successful request.
final class RequestSuccessState<TOut, TError>
    extends RequestState<TOut, TError> {
  /// Creates a new [RequestSuccessState] with the given [data].
  RequestSuccessState(this.data);

  /// The data returned by the request.
  final TOut data;

  @override
  List<Object?> get props => [data];
}

/// Represents a successful request with empty data.
final class RequestEmptyState<TOut, TError> extends RequestState<TOut, TError> {
  /// Creates a new [RequestEmptyState].
  RequestEmptyState(this.data);

  /// The data returned by the request.
  final TOut data;

  @override
  List<Object?> get props => [data];
}

/// Represents a failed request.
final class RequestErrorState<TOut, TError> extends RequestState<TOut, TError> {
  /// Creates a new [RequestErrorState] with the given [error], [exception] and
  /// [stackTrace].
  RequestErrorState({this.error, this.exception, this.stackTrace});

  /// The error returned by the request.
  final TError? error;

  /// The exception thrown when processing the request.
  final Object? exception;

  /// The stack trace of the exception thrown when processing the request.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error, exception, stackTrace];
}
