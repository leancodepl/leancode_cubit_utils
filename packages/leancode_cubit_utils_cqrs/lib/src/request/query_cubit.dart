import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// A mixin that handles the result of a CQRS query.
mixin QueryResultHandler<TRes, TOut>
    on BaseRequestCubit<QueryResult<TRes>, TRes, TOut, QueryError> {
  @override
  Future<RequestState<TOut, QueryError>> handleResult(
    QueryResult<TRes> result,
  ) async {
    if (result case QuerySuccess(:final data)) {
      final mappedData = map(data);
      if (isEmpty(mappedData)) {
        logger.warning('Query success but data is empty');
        return RequestEmptyState(mappedData);
      }
      logger.info('Query success. Data: $data');
      return RequestSuccessState(mappedData);
    } else if (result case QueryFailure(:final error)) {
      logger.severe('Query error. Error: $error');
      try {
        return await handleError(RequestErrorState(error: error));
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
  QueryCubit(super.loggerTag, {super.requestMode});
}

/// Base class for all request cubits that perform a CQRS query
/// and require arguments.
abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends ArgsRequestCubit<TArgs, QueryResult<TRes>, TRes, TOut, QueryError>
    with QueryResultHandler {
  /// Creates a new [ArgsRequestCubit] with the given [requestMode].
  ArgsQueryCubit(super.loggerTag, {super.requestMode});
}
