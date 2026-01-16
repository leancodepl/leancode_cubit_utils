import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/src/request/args_query_cubit/simple_args_query_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

import 'args_query_cubit.dart';

/// Provides a [ArgsQueryCubit] specialized for [QueryResult] that is
/// automatically disposed without having to use BlocProvider and requires
/// arguments. It is a wrapper of [useBloc] that creates a
/// [SimpleArgsQueryCubit].
SimpleArgsQueryCubit<TArgs, TOut> useArgsQueryCubit<TArgs, TOut>(
  ArgsRequest<TArgs, QueryResult<TOut>> request, {
  String loggerTag = 'SimpleArgsQueryCubit',
  EmptyChecker<TOut>? isEmpty,
  RequestMode? requestMode,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () => SimpleArgsQueryCubit<TArgs, TOut>(
      loggerTag,
      request,
      isEmpty: isEmpty,
      requestMode: requestMode,
    ),
    keys: keys,
  );
}
