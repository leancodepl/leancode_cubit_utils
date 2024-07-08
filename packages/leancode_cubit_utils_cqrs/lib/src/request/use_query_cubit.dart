import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Provides a [SimpleQueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and does not require any arguments. It is a wrapper of [useBloc] that creates a [SimpleQueryCubit].
SimpleQueryCubit<TOut> useQueryCubit<TOut>(
  Request<QueryResult<TOut>> request, {
  String loggerTag = 'SimpleQueryCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () {
      final cubit = SimpleQueryCubit<TOut>(
        loggerTag,
        customRequest: request,
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

/// Provides a [SimpleArgsQueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and requires arguments. It is a wrapper of [useBloc] that creates a [SimpleArgsQueryCubit].
SimpleArgsQueryCubit<TArgs, TOut> useArgsQueryCubit<TArgs, TOut>(
  ArgsRequest<TArgs, QueryResult<TOut>> request, {
  String loggerTag = 'SimpleArgsQueryCubit',
  RequestMode? requestMode,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () => SimpleArgsQueryCubit<TArgs, TOut>(
      loggerTag,
      customRequest: request,
      requestMode: requestMode,
    ),
    keys,
  );
}
