import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/query/query_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Implementation of [QueryCubit] created in order to be used by [useQueryCubit].
class SimpleQueryCubit<TOut> extends QueryCubit<TOut, TOut> {
  /// Creates a new [SimpleQueryCubit].
  SimpleQueryCubit(
    super.loggerTag,
    this._customRequest, {
    super.requestMode,
  });

  /// The request to be executed.
  final QueryRequest<TOut> _customRequest;

  @override
  TOut map(TOut data) => data;

  @override
  Future<QueryResult<TOut>> request() => _customRequest();
}

/// Creates a new [SimpleQueryCubit] with the given [loggerTag], [query] and
/// [requestMode].
QueryCubit<TOut, TOut> useQueryCubit<TOut>(
  QueryRequest<TOut> query, {
  String loggerTag = 'SimpleQueryCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () {
      final cubit = SimpleQueryCubit<TOut>(
        loggerTag,
        query,
        requestMode: requestMode,
      );
      if (callOnCreate) {
        cubit.run();
      }
      return cubit;
    },
    keys,
  );
}
