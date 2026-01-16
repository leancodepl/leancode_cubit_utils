import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/query_result_handler.dart';

/// Base class for all request cubits that perform a CQRS query
/// and require arguments.
abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends ArgsRequestCubit<TArgs, QueryResult<TRes>, TOut, QueryError>
    with QueryResultHandler<TRes, TOut> {
  /// Creates a new [ArgsRequestCubit] with the given [requestMode].
  ArgsQueryCubit(
    super.loggerTag, {
    super.requestMode,
    EmptyChecker<TOut>? isEmpty,
  }) : _isEmpty = isEmpty;

  /// The function to check if the data is empty.
  final EmptyChecker<TOut>? _isEmpty;

  @override
  bool isEmpty(TOut data) => _isEmpty?.call(data) ?? false;
}
