import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/query_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Implementation of [QueryCubit] created in order to be used by [useQueryCubit].
class SimpleQueryCubit<TOut> extends QueryCubit<TOut, TOut> {
  /// Creates a new [SimpleQueryCubit].
  SimpleQueryCubit(
    super.loggerTag,
    this.customRequest, {
    super.requestMode,
  });

  /// The request to be executed.
  final QueryRequest<TOut> customRequest;

  @override
  TOut map(TOut data) => data;

  @override
  Future<QueryResult<TOut>> request() => customRequest();
}

/// Creates a new [SimpleQueryCubit] with the given [loggerTag], [query] and
/// [requestMode].
QueryCubit<TOut, TOut> useQueryCubit<TOut>(
  QueryRequest<TOut> query, {
  String loggerTag = 'SimpleQueryCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
}) {
  final cubit = useBloc(
    () => SimpleQueryCubit<TOut>(
      loggerTag,
      query,
      requestMode: requestMode,
    ),
  );
  useEffect(
    () {
      if (callOnCreate) {
        cubit.get();
      }
      return null;
    },
    [cubit],
  );
  return cubit;
}
