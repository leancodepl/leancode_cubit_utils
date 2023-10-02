import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Implementation of [ArgsQueryCubit] created in order to be used by [useArgsQueryCubit].
class SimpleArgsQueryCubit<TArgs, TOut>
    extends ArgsQueryCubit<TArgs, TOut, TOut> {
  /// Creates a new [SimpleArgsQueryCubit].
  SimpleArgsQueryCubit(
    super.loggerTag,
    this.customRequest, {
    super.requestMode,
  });

  /// The request to be executed.
  final QueryArgsRequest<TArgs, TOut> customRequest;

  @override
  TOut map(TOut data) => data;

  @override
  Future<QueryResult<TOut>> request(TArgs args) => customRequest(args);
}

/// Creates a new [SimpleArgsQueryCubit] with the given [loggerTag], [query] and
/// [requestMode].
SimpleArgsQueryCubit<TArgs, TOut> useArgsQueryCubit<TArgs, TOut>({
  String loggerTag = 'SimpleArgsQueryCubit',
  required QueryArgsRequest<TArgs, TOut> query,
  RequestMode? requestMode,
}) {
  return useBloc(
    () => SimpleArgsQueryCubit<TArgs, TOut>(
      loggerTag,
      query,
      requestMode: requestMode,
    ),
  );
}
