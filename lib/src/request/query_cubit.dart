part of 'request_cubit.dart';

/// Base class for all request cubits that perform a CQRS query
/// and do not require any arguments.
abstract class QueryCubit<TRes, TOut>
    extends RequestCubit<QueryResult<TRes>, TRes, TOut, QueryError> {
  /// Creates a new [RequestCubit] with the given [requestMode].
  QueryCubit(
    super.loggerTag, {
    super.requestMode,
  }) : super(resultHandler: queryResultHandler<TRes, TOut>);
}

/// Base class for all request cubits that perform a CQRS query
/// and require arguments.
abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends ArgsRequestCubit<TArgs, QueryResult<TRes>, TRes, TOut, QueryError> {
  /// Creates a new [ArgsRequestCubit] with the given [requestMode].
  ArgsQueryCubit(
    super.loggerTag, {
    super.requestMode,
  }) : super(resultHandler: queryResultHandler<TRes, TOut>);
}
