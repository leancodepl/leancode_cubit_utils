import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
import 'package:leancode_cubit_utils/src/request/result_handlers.dart';

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
