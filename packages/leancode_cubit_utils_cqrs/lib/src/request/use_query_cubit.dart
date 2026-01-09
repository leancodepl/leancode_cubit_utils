import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

import 'query_cubit.dart';

/// Simplified implementation of [QueryCubit] created in order to be used by [useQueryCubit].
class SimpleQueryCubit<TOut> extends QueryCubit<TOut, TOut> {
  /// Creates a new [SimpleQueryCubit].
  SimpleQueryCubit(
    super.loggerTag,
    this._customRequest, {
    EmptyChecker<TOut>? isEmpty,
    super.requestMode,
  }) : _isEmpty = isEmpty;

  /// The request to be executed.
  final Request<QueryResult<TOut>> _customRequest;

  /// The function to check if the data is empty.
  final EmptyChecker<TOut>? _isEmpty;

  @override
  Future<QueryResult<TOut>> request() => _customRequest();

  @override
  TOut map(TOut data) => data;

  @override
  bool isEmpty(TOut data) => _isEmpty?.call(data) ?? false;
}

/// Provides a [QueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and does not require any arguments. It is a wrapper of [useBloc] that creates a [SimpleQueryCubit].
SimpleQueryCubit<TOut> useQueryCubit<TOut>(
  Request<QueryResult<TOut>> request, {
  String loggerTag = 'SimpleQueryWithEmptyCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
  EmptyChecker<TOut>? isEmpty,
}) {
  return useBloc(() {
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
  }, keys: keys);
}

/// Simplified implementation of [ArgsQueryCubit] created in order to be used by [useArgsQueryCubit].
class SimpleArgsQueryCubit<TArgs, TOut>
    extends ArgsQueryCubit<TArgs, TOut, TOut> {
  /// Creates a new [SimpleArgsQueryCubit].
  SimpleArgsQueryCubit(
    super.loggerTag,
    this._customRequest, {
    EmptyChecker<TOut>? isEmpty,
    super.requestMode,
  }) : _isEmpty = isEmpty;

  /// The request to be executed.
  final ArgsRequest<TArgs, QueryResult<TOut>> _customRequest;

  @override
  Future<QueryResult<TOut>> request(TArgs args) => _customRequest(args);

  @override
  TOut map(TOut data) => data;

  @override
  bool isEmpty(TOut data) => _isEmpty?.call(data) ?? false;
}

/// Provides a [ArgsQueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and requires arguments. It is a wrapper of [useBloc] that creates a [SimpleArgsQueryCubit].
SimpleArgsQueryCubit<TArgs, TOut> useArgsQueryCubit<TArgs, TOut>(
  ArgsRequest<TArgs, QueryResult<TOut>> request, {
  String loggerTag = 'SimpleArgsQueryCubit',
  RequestMode? requestMode,
  EmptyChecker<TOut>? isEmpty,
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
