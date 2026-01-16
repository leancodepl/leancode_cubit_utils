import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/query_result_handler.dart';

/// Base class for all request cubits that perform a CQRS query
/// and do not require any arguments.
abstract class QueryCubit<TRes, TOut>
    extends RequestCubit<QueryResult<TRes>, TOut, QueryError>
    with QueryResultHandler<TRes, TOut> {
  /// Creates a new [RequestCubit] with the given [requestMode].
  QueryCubit(
    super.loggerTag, {
    EmptyChecker<TOut>? isEmpty,
    super.requestMode,
  }) : _isEmpty = isEmpty;

  /// The function to check if the data is empty.
  final EmptyChecker<TOut>? _isEmpty;

  @override
  bool isEmpty(TOut data) => _isEmpty?.call(data) ?? false;
}
