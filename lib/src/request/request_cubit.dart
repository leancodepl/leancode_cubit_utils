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

/// Signature for a function that maps request error to other state.
typedef ErrorMapper<TOut, TError> = Future<TOut> Function(
  RequestErrorState<TOut, TError>,
);

/// Signature for a function that handles the request result and returns the
/// corresponding state.
typedef ResultHandler<TRes, TData, TOut, TError>
    = Future<RequestState<TOut, TError>> Function(
  TRes result,
  Future<RequestErrorState<TOut, TError>> Function(
    RequestErrorState<TOut, TError> errorState,
  ),
  TOut Function(TData) dataMapper,
  Logger logger,
);

/// Defines how to handle a new request when the previous one is still running.
enum RequestMode {
  /// When a new request is triggered while the previous one is still running,
  /// the previous request is cancelled and the new one is executed.
  replace,

  /// When a new request is triggered while the previous one is still running,
  /// the new request is ignored.
  ignore;
}

/// Base class for all request cubits.
abstract class BaseRequestCubit<TRes, TData, TOut, TError>
    extends Cubit<RequestState<TOut, TError>> {
  /// Creates a new [BaseRequestCubit] with the given [loggerTag] and [requestMode].
  BaseRequestCubit(
    String loggerTag, {
    required this.resultHandler,
    this.requestMode,
  })  : _logger = Logger(loggerTag),
        super(RequestInitialState());

  final Logger _logger;

  ///
  final ResultHandler<TRes, TData, TOut, TError> resultHandler;

  /// The request mode used by this cubit to handle duplicated requests.
  final RequestMode? requestMode;

  CancelableOperation<TRes>? _operation;

  Future<void> _get(
    Future<TRes> Function() callback, {
    bool isRefresh = false,
  }) async {
    try {
      switch (requestMode ?? RequestCubitConfig.requestMode) {
        case RequestMode.replace:
          await _operation?.cancel();
        case RequestMode.ignore:
          if (_operation?.isCompleted == false) {
            _logger.info('Previous operation is not completed. Ignoring.');
            return;
          }
      }

      if (isRefresh) {
        _logger.info('Refreshing request.');
        emit(
          RequestRefreshState(
            switch (state) {
              RequestSuccessState(:final data) => data,
              RequestRefreshState(:final data) => data,
              _ => null,
            },
          ),
        );
      } else {
        _logger.info('Request started.');
        emit(RequestLoadingState());
      }

      _operation = CancelableOperation.fromFuture(
        callback(),
        onCancel: () {
          _logger.info('Canceling previous operation.');
        },
      );

      final result = await _operation?.valueOrCancellation();
      if (result == null) {
        return;
      }

      emit(await resultHandler(result, handleError, map, _logger));
    } catch (e, s) {
      _logger.severe('Request error. Exception: $e. Stack trace: $s');
      try {
        emit(
          await handleError(
            RequestErrorState(exception: e, stackTrace: s),
          ),
        );
      } catch (e, s) {
        _logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(RequestErrorState<TOut, TError>(exception: e, stackTrace: s));
      }
    }
  }

  /// Maps the given [data] to the output type [TOut].
  TOut map(TData data);

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
abstract class RequestCubit<TRes, TData, TOut, TError>
    extends BaseRequestCubit<TRes, TData, TOut, TError> {
  /// Creates a new [RequestCubit] with the given [requestMode].
  RequestCubit(
    super.loggerTag, {
    required super.resultHandler,
    super.requestMode,
  });

  /// Gets the data from the request and emits the corresponding state.
  Future<void> get() => _get(request);

  /// A request to be executed.
  Future<TRes> request();

  /// Refreshes the request.
  @override
  Future<void> refresh() {
    return _get(request, isRefresh: true);
  }
}

/// Base class for all request cubits which require arguments.
abstract class ArgsRequestCubit<TArgs, TRes, TData, TOut, TError>
    extends BaseRequestCubit<TRes, TData, TOut, TError> {
  /// Creates a new [ArgsRequestCubit] with the given [requestMode].
  ArgsRequestCubit(
    super.loggerTag, {
    super.requestMode,
    required super.resultHandler,
  });

  TArgs? _lastGetArgs;

  /// The arguments used by this cubit to refresh the request.
  TArgs? get lastFetchArgs => _lastGetArgs;

  /// Gets the data from the request and emits the corresponding state.
  Future<void> get(TArgs args) {
    _lastGetArgs = args;
    return _get(() => request(args));
  }

  /// A request to be executed.
  Future<TRes> request(TArgs args);

  @override
  Future<void> refresh() {
    if (_lastGetArgs == null) {
      _logger.severe('No request was executed yet. Cannot refresh.');
      throw StateError('No request was executed yet. Cannot refresh.');
    } else {
      // ignore: null_check_on_nullable_type_parameter
      return _get(() => request(_lastGetArgs!), isRefresh: true);
    }
  }
}

/// Represents the state of a request.
sealed class RequestState<TOut, TError> with EquatableMixin {}

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
  RequestRefreshState([this.data]);

  /// The previous data.
  final TOut? data;

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

/// Represents a failed request.
final class RequestErrorState<TOut, TError> extends RequestState<TOut, TError> {
  /// Creates a new [RequestErrorState] with the given [error], [exception] and
  /// [stackTrace].
  RequestErrorState({
    this.error,
    this.exception,
    this.stackTrace,
  });

  /// The error returned by the request.
  final TError? error;

  /// The exception thrown when processing the request.
  final Object? exception;

  /// The stack trace of the exception thrown when processing the request.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error, exception, stackTrace];
}
