import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';

/// Simplified implementation of [QueryCubit] where TRes equals TOut, used by [useQueryCubit].
class SimpleQueryCubit<TOut> extends QueryCubit<TOut, TOut> {
  /// Creates a new [SimpleQueryCubit].
  SimpleQueryCubit(
    super.loggerTag, {
    required this.customRequest,
    super.requestMode,
  });

  /// The request to be executed.
  final Request<QueryResult<TOut>> customRequest;

  @override
  Future<QueryResult<TOut>> request() => customRequest();

  @override
  TOut map(TOut data) => data;
}

/// Simplified implementation of [ArgsQueryCubit] where TRes equals TOut, used by [useArgsQueryCubit].
class SimpleArgsQueryCubit<TArgs, TOut>
    extends ArgsQueryCubit<TArgs, TOut, TOut> {
  /// Creates a new [SimpleArgsQueryCubit].
  SimpleArgsQueryCubit(
    super.loggerTag, {
    required this.customRequest,
    super.requestMode,
  });

  /// The request to be executed.
  final ArgsRequest<TArgs, QueryResult<TOut>> customRequest;

  @override
  Future<QueryResult<TOut>> request(TArgs args) => customRequest(args);

  @override
  TOut map(TOut data) => data;
}
