import 'dart:async';

import 'package:async/async.dart';
import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

/// Defines how to handle a new request when the previous one is still running.
enum RefreshMode {
  /// When a new request is triggered while the previous one is still running,
  /// the previous request is cancelled and the new one is executed.
  replace,

  /// When a new request is triggered while the previous one is still running,
  /// the new request is ignored.
  ignore;
}

/// Base class for all query cubits.
abstract class BaseQueryCubit<TRes, TOut> extends Cubit<QueryState<TOut>> {
  /// Creates a new [BaseQueryCubit] with the given [logger] and [refreshMode].
  BaseQueryCubit(this.logger, this.refreshMode) : super(QueryInitialState());

  /// The logger used by this cubit.
  final Logger logger;

  /// The refresh mode used by this cubit.
  final RefreshMode refreshMode;

  CancelableOperation<QueryResult<TRes>>? _operation;

  Future<void> _get(
    Future<QueryResult<TRes>> Function() callback, {
    bool isRefresh = false,
  }) async {
    switch (refreshMode) {
      case RefreshMode.replace:
        unawaited(_operation?.cancel());
      case RefreshMode.ignore:
        if (_operation?.isCompleted == false) {
          logger.info('Previous operation is not completed. Ignoring.');
          return;
        }
    }

    logger.info('Query started. Is refresh: $isRefresh');
    emit(QueryLoadingState(isRefresh: isRefresh));

    _operation = CancelableOperation.fromFuture(
      callback(),
      onCancel: () {
        logger.info('Previous operation is not completed. Cancelling.');
      },
    );

    final result = await _operation?.value;

    if (result case QuerySuccess(:final data)) {
      logger.info('Query success. Data: $data');
      try {
        final mappedData = map(data);
        emit(QuerySuccessState(mappedData));
      } catch (e, s) {
        logger.severe(
          'Error while mapping query result. Error: $e, StackTrace: $s',
        );
        emit(
          QueryErrorState(
            exception: e,
            stackTrace: s,
          ),
        );
      }
    } else if (result case QueryFailure(:final error)) {
      logger.severe('Query error. Error: $error');
      try {
        emit(onQueryError(error));
      } catch (e, s) {
        logger.severe(
          'Error while handling query error. Error: $e, StackTrace: $s',
        );
        emit(
          QueryErrorState(
            error: error,
            exception: e,
            stackTrace: s,
          ),
        );
      }
    }
  }

  /// Maps the given [data] to the output type [TOut].
  TOut map(TRes data);

  /// Handles the given [error] and returns the corresponding state.
  QueryErrorState<TOut> onQueryError(QueryError error) {
    return QueryErrorState(error: error);
  }

  /// Refreshes the query. Handling duplicated requests depends on the
  /// [refreshMode].
  void refresh();
}

/// Base class for all query cubits which don't require any arguments.
abstract class QueryCubit<TRes, TOut> extends BaseQueryCubit<TRes, TOut> {
  /// Creates a new [QueryCubit] with the given [logger] and [refreshMode].
  QueryCubit(super.logger, super.refreshMode);

  /// Gets the data from the request and emits the corresponding state.
  Future<void> get({bool isRefresh = false}) {
    return _get(request, isRefresh: isRefresh);
  }

  /// A request to be executed.
  Future<QueryResult<TRes>> request();

  /// Refreshes the query.
  @override
  void refresh() => get(isRefresh: true);
}

/// Base class for all query cubits which require arguments.
abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends BaseQueryCubit<TRes, TOut> {
  /// Creates a new [ArgsQueryCubit] with the given [logger] and [refreshMode].
  ArgsQueryCubit(super.logger, super.refreshMode);

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
  void refresh() {
    if (refreshArgs == null) {
      logger.severe('Args is null. Refresh is not possible.');
    } else {
      // ignore: null_check_on_nullable_type_parameter
      get(refreshArgs!, isRefresh: true);
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
