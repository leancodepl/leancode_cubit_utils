import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Implementation of [ArgsQueryCubit] created in order to be used by [useArgsQueryCubit].
class HookArgsQueryCubit<TArgs, TRes, TOut>
    extends ArgsQueryCubit<TArgs, TRes, TOut> {
  /// Creates a new [HookArgsQueryCubit].
  HookArgsQueryCubit(
    super.loggerTag,
    this.customRequest,
    this.customMap, {
    super.requestMode,
    this.onCustomQueryError,
  });

  /// The request to be executed.
  final QueryArgsRequest<TArgs, TRes> customRequest;

  /// The mapper to be used to map the response.
  final QueryResponseMapper<TRes, TOut> customMap;

  /// The method to be used to handle the error state.
  final QueryErrorMapper<TOut>? onCustomQueryError;

  @override
  TOut map(TRes data) => customMap(data);

  @override
  Future<QueryResult<TRes>> request(TArgs args) => customRequest(args);

  @override
  Future<QueryState<TOut>> onQueryError(QueryErrorState<TOut> errorState) {
    return onCustomQueryError?.call(errorState) ??
        super.onQueryError(errorState);
  }
}

/// Creates a new [HookQueryCubit] with the given [loggerTag], [query] and
/// [map].
HookArgsQueryCubit<TArgs, TRes, TOut> useArgsQueryCubit<TArgs, TRes, TOut>({
  required String loggerTag,
  required QueryArgsRequest<TArgs, TRes> query,
  required QueryResponseMapper<TRes, TOut> map,
  RequestMode? requestMode,
  QueryErrorMapper<TOut>? onQueryError,
}) {
  return useBloc(
    () => HookArgsQueryCubit<TArgs, TRes, TOut>(
      loggerTag,
      query,
      map,
      requestMode: requestMode,
      onCustomQueryError: onQueryError,
    ),
  );
}
