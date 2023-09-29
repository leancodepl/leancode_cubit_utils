import 'dart:async';

import 'package:async/async.dart';
import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/query_cubit_config.dart';
import 'package:logging/logging.dart';

/// Signature for a function that returns a [QueryResult].
typedef QueryRequest<TRes> = Future<QueryResult<TRes>> Function();

/// Signature for a function that returns a [QueryResult] and takes arguments.
typedef QueryArgsRequest<TArgs, TRes> = Future<QueryResult<TRes>> Function(
  TArgs,
);

/// Signature for a function that maps query response of to the output type.
typedef QueryResponseMapper<TRes, TOut> = TOut Function(TRes);

/// Signature for a function that maps query error to other state.
typedef QueryErrorMapper<TOut> = Future<QueryState<TOut>> Function(
  QueryErrorState<TOut>,
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

/// Base class for all query cubits.
abstract class BaseQueryCubit<TRes, TOut> extends Cubit<QueryState<TOut>> {
  /// Creates a new [BaseQueryCubit] with the given [loggerTag] and [requestMode].
  BaseQueryCubit(
    String loggerTag, {
    this.requestMode,
  })  : _logger = Logger(loggerTag),
        super(QueryInitialState());

  final Logger _logger;

  /// The request mode used by this cubit to handle duplicated requests.
  final RequestMode? requestMode;

  CancelableOperation<QueryResult<TRes>>? _operation;

  Future<void> _get(
    Future<QueryResult<TRes>> Function() callback, {
    bool isRefresh = false,
  }) async {
    try {
      switch (requestMode ?? QueryCubitConfig.requestMode) {
        case RequestMode.replace:
          await _operation?.cancel();
        case RequestMode.ignore:
          if (_operation?.isCompleted == false) {
            _logger.info('Previous operation is not completed. Ignoring.');
            return;
          }
      }

      _logger.info('Query started. Is refresh: $isRefresh');
      emit(QueryLoadingState(isRefresh: isRefresh));

      _operation = CancelableOperation.fromFuture(
        callback(),
        onCancel: () {
          _logger.info('Previous operation is not completed. Cancelling.');
        },
      );

      final result = await _operation?.value;

      if (result case QuerySuccess(:final data)) {
        _logger.info('Query success. Data: $data');
        emit(QuerySuccessState(map(data)));
      } else if (result case QueryFailure(:final error)) {
        _logger.severe('Query error. Error: $error');
        await onQueryError(QueryErrorState(error: error));
      }
    } catch (e, s) {
      _logger.severe('Query error. Exception: $e. Stack trace: $s');
      await onQueryError(
        QueryErrorState(
          exception: e,
          stackTrace: s,
        ),
      );
    }
  }

  /// Maps the given [data] to the output type [TOut].
  TOut map(TRes data);

  /// Handles the given [errorState] and returns the corresponding state.
  Future<QueryState<TOut>> onQueryError(
    QueryErrorState<TOut> errorState,
  ) async {
    return errorState;
  }

  /// Refreshes the query. Handling duplicated requests depends on the
  /// [requestMode].
  Future<void> refresh();
}

/// Base class for all query cubits which don't require any arguments.
abstract class QueryCubit<TRes, TOut> extends BaseQueryCubit<TRes, TOut> {
  /// Creates a new [QueryCubit] with the given [requestMode].
  QueryCubit(
    super.loggerTag, {
    super.requestMode,
  });

  /// Gets the data from the request and emits the corresponding state.
  Future<void> get({bool isRefresh = false}) {
    return _get(request, isRefresh: isRefresh);
  }

  /// A request to be executed.
  Future<QueryResult<TRes>> request();

  /// Refreshes the query.
  @override
  Future<void> refresh() async {
    await _get(request, isRefresh: true);
  }
}

/// Base class for all query cubits which require arguments.
abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends BaseQueryCubit<TRes, TOut> {
  /// Creates a new [ArgsQueryCubit] with the given [requestMode].
  ArgsQueryCubit(
    super.loggerTag, {
    super.requestMode,
  });

  /// The arguments used by this cubit to refresh the query.
  TArgs? refreshArgs;

  /// Gets the data from the request and emits the corresponding state.
  Future<void> get(
    TArgs args, {
    bool isRefresh = false,
  }) {
    refreshArgs = args;
    return _get(() => request(args), isRefresh: isRefresh);
  }

  /// A request to be executed.
  Future<QueryResult<TRes>> request(TArgs args);

  @override
  Future<void> refresh() async {
    if (refreshArgs == null) {
      _logger.severe('No query was executed yet. Cannot refresh.');
    } else {
      // ignore: null_check_on_nullable_type_parameter
      await _get(() => request(refreshArgs!), isRefresh: true);
    }
  }
}

/// Represents the state of a query.
sealed class QueryState<TOut> with EquatableMixin {}

/// Represents the initial state of a query.
final class QueryInitialState<TOut> extends QueryState<TOut> {
  @override
  List<Object?> get props => [];
}

/// Represents the loading state of a query.
final class QueryLoadingState<TOut> extends QueryState<TOut> {
  /// Creates a new [QueryLoadingState] with the given [isRefresh].
  QueryLoadingState({required this.isRefresh});

  /// Whether the loading query is a refresh.
  final bool isRefresh;

  @override
  List<Object?> get props => [isRefresh];
}

/// Represents a successful query.
final class QuerySuccessState<TOut> extends QueryState<TOut> {
  /// Creates a new [QuerySuccessState] with the given [data].
  QuerySuccessState(this.data);

  /// The data returned by the query.
  final TOut data;

  @override
  List<Object?> get props => [data];
}

/// Represents a failed query.
final class QueryErrorState<TOut> extends QueryState<TOut> {
  /// Creates a new [QueryErrorState] with the given [error], [exception] and
  /// [stackTrace].
  QueryErrorState({
    this.error,
    this.exception,
    this.stackTrace,
  });

  /// The error returned by the query.
  final QueryError? error;

  /// The exception thrown when processing the query.
  final Object? exception;

  /// The stack trace of the exception thrown when processing the query.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error, exception, stackTrace];
}
