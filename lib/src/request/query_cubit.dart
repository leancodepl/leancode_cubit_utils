import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
import 'package:logging/logging.dart';

/// A mixin that handles the result of a CQRS query.
mixin QueryResultHandler {
  /// Handles the result of a CQRS query. It logs the result and maps it to a [RequestState].
  Future<RequestState<TOut, QueryError>> queryResultHandler<TData, TOut>(
    QueryResult<TData> result,
    Future<RequestErrorState<TOut, QueryError>> Function(
      RequestErrorState<TOut, QueryError> errorState,
    ) errorMapper,
    TOut Function(TData) dataMapper,
    Logger logger,
  ) async {
    if (result case QuerySuccess(:final data)) {
      logger.info('Query success. Data: $data');
      return RequestSuccessState(dataMapper(data));
    } else if (result case QueryFailure(:final error)) {
      logger.severe('Query error. Error: $error');
      try {
        return await errorMapper(RequestErrorState(error: error));
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        return RequestErrorState(exception: e, stackTrace: s);
      }
    } else {
      return RequestErrorState();
    }
  }
}

/// Base class for all request cubits that perform a CQRS query
/// and do not require any arguments.
abstract class QueryCubit<TRes, TOut>
    extends RequestCubit<QueryResult<TRes>, TRes, TOut, QueryError>
    with QueryResultHandler {
  /// Creates a new [RequestCubit] with the given [requestMode].
  QueryCubit(
    super.loggerTag, {
    super.requestMode,
  }) : super(resultHandler: queryResultHandler<TRes, TOut>);
}

/// Base class for all request cubits that perform a CQRS query
/// and require arguments.
abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends ArgsRequestCubit<TArgs, QueryResult<TRes>, TRes, TOut, QueryError>
    with QueryResultHandler {
  /// Creates a new [ArgsRequestCubit] with the given [requestMode].
  ArgsQueryCubit(
    super.loggerTag, {
    super.requestMode,
  }) : super(resultHandler: queryResultHandler<TRes, TOut>);
}
