import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/query_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Implementation of [QueryCubit] created in order to be used by [useQueryCubit].
class HookQueryCubit<TRes, TOut> extends QueryCubit<TRes, TOut> {
  /// Creates a new [HookQueryCubit].
  HookQueryCubit(
    super.loggerTag,
    this.customRequest,
    this.customMap, {
    super.requestMode,
    this.onCustomQueryError,
  });

  /// The request to be executed.
  final QueryRequest<TRes> customRequest;

  /// The mapper to be used to map the response.
  final QueryResponseMapper<TRes, TOut> customMap;

  /// The method to be used to handle the error state.
  final QueryErrorMapper<TOut>? onCustomQueryError;

  @override
  TOut map(TRes data) => customMap(data);

  @override
  Future<QueryResult<TRes>> request() => customRequest();

  @override
  Future<QueryState<TOut>> onQueryError(QueryErrorState<TOut> errorState) {
    return onCustomQueryError?.call(errorState) ??
        super.onQueryError(errorState);
  }
}

/// Creates a new [HookQueryCubit] with the given [loggerTag], [query] and
/// [map].
QueryCubit<TRes, TOut> useQueryCubit<TRes, TOut>({
  required String loggerTag,
  required QueryRequest<TRes> query,
  required QueryResponseMapper<TRes, TOut> map,
  RequestMode? requestMode,
  QueryErrorMapper<TOut>? onQueryError,
}) {
  return useBloc(
    () => HookQueryCubit<TRes, TOut>(
      loggerTag,
      query,
      map,
      requestMode: requestMode,
      onCustomQueryError: onQueryError,
    ),
  );
}
