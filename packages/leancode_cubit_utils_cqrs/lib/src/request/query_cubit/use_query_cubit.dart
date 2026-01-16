import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/query_cubit/query_cubit.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/query_cubit/simple_query_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Provides a [QueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and does not require any arguments. It is a wrapper of [useBloc] that creates a [SimpleQueryCubit].
SimpleQueryCubit<TOut> useQueryCubit<TOut>(
  Request<QueryResult<TOut>> request, {
  String loggerTag = 'SimpleQueryWithEmptyCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  EmptyChecker<TOut>? isEmpty,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () {
      final cubit = SimpleQueryCubit<TOut>(
        loggerTag,
        request,
        isEmpty: isEmpty,
        requestMode: requestMode,
      );
      if (callOnCreate) {
        cubit.run();
      }
      return cubit;
    },
    keys: keys,
  );
}
