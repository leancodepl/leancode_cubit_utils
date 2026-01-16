import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/args_query_cubit/args_query_cubit.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/args_query_cubit/use_args_query_cubit.dart';

/// Simplified implementation of [ArgsQueryCubit] created in order to be used
/// by [useArgsQueryCubit].
class SimpleArgsQueryCubit<TArgs, TOut>
    extends ArgsQueryCubit<TArgs, TOut, TOut> {
  /// Creates a new [SimpleArgsQueryCubit].
  SimpleArgsQueryCubit(
    super.loggerTag,
    this._customRequest, {
    super.isEmpty,
    super.requestMode,
  });

  /// The request to be executed.
  final ArgsRequest<TArgs, QueryResult<TOut>> _customRequest;

  @override
  Future<QueryResult<TOut>> request(TArgs args) => _customRequest(args);

  @override
  TOut map(TOut data) => data;
}
