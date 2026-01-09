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
    super.requestMode,
  });

  /// The request to be executed.
  final Request<QueryResult<TOut>> _customRequest;

  @override
  Future<QueryResult<TOut>> request() => _customRequest();

  @override
  TOut map(TOut data) => data;
}

/// Provides a [QueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and does not require any arguments. It is a wrapper of [useBloc] that creates a [SimpleQueryCubit].
SimpleQueryCubit<TOut> useQueryCubit<TOut>(
  Request<QueryResult<TOut>> request, {
  String loggerTag = 'SimpleQueryCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
  EmptyChecker<TOut>? isEmpty,
}) {
  return useBloc(
    () {
      final cubit = SimpleQueryCubit<TOut>(
        loggerTag,
        request,
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

/// Simplified implementation of [QueryCubit] created in order to be used by [useQueryCubit].
/// Differ from [SimpleQueryCubit] because it uses a custom function to check if the data is empty.
class SimpleQueryWithEmptyCubit<TOut> extends QueryCubit<TOut, TOut> {
  /// Creates a new [SimpleQueryWithEmptyCubit].
  SimpleQueryWithEmptyCubit(
    super.loggerTag,
    this._customRequest,
    this._isEmpty, {
    super.requestMode,
  });

  /// The request to be executed.
  final Request<QueryResult<TOut>> _customRequest;

  /// The function to check if the data is empty.
  final EmptyChecker<TOut> _isEmpty;

  @override
  Future<QueryResult<TOut>> request() => _customRequest();

  @override
  TOut map(TOut data) => data;

  @override
  bool isEmpty(TOut data) => _isEmpty(data);
}

/// Provides a [QueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and does not require any arguments. It is a wrapper of [useBloc] that creates a [SimpleQueryWithEmptyCubit].
/// Differ from [useQueryCubit] because it uses a custom function to check if the data is empty.
SimpleQueryWithEmptyCubit<TOut> useQueryWithEmptyCubit<TOut>(
  Request<QueryResult<TOut>> request,
  EmptyChecker<TOut> isEmpty, {
  String loggerTag = 'SimpleQueryWithEmptyCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () {
      final cubit = SimpleQueryWithEmptyCubit<TOut>(
        loggerTag,
        request,
        isEmpty,
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

/// Simplified implementation of [ArgsQueryCubit] created in order to be used by [useArgsQueryCubit].
class SimpleArgsQueryCubit<TArgs, TOut>
    extends ArgsQueryCubit<TArgs, TOut, TOut> {
  /// Creates a new [SimpleArgsQueryCubit].
  SimpleArgsQueryCubit(
    super.loggerTag,
    this._customRequest, {
    super.requestMode,
  });

  /// The request to be executed.
  final ArgsRequest<TArgs, QueryResult<TOut>> _customRequest;

  @override
  Future<QueryResult<TOut>> request(TArgs args) => _customRequest(args);

  @override
  TOut map(TOut data) => data;
}

/// Provides a [ArgsQueryCubit] specialized for [QueryResult] that is automatically disposed without having
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
      request,
      requestMode: requestMode,
    ),
    keys: keys,
  );
}

/// Simplified implementation of [ArgsQueryCubit] created in order to be used by [useArgsQueryCubit].
/// Differ from [SimpleArgsQueryCubit] because it uses a custom function to check if the data is empty.
class SimpleArgsQueryWithEmptyCubit<TArgs, TOut>
    extends ArgsQueryCubit<TArgs, TOut, TOut> {
  /// Creates a new [SimpleArgsQueryWithEmptyCubit].
  SimpleArgsQueryWithEmptyCubit(
    super.loggerTag,
    this._customRequest,
    this._isEmpty, {
    super.requestMode,
  });

  /// The request to be executed.
  final ArgsRequest<TArgs, QueryResult<TOut>> _customRequest;

  /// The function to check if the data is empty.
  final EmptyChecker<TOut> _isEmpty;

  @override
  Future<QueryResult<TOut>> request(TArgs args) => _customRequest(args);

  @override
  TOut map(TOut data) => data;

  @override
  bool isEmpty(TOut data) => _isEmpty(data);
}

/// Provides a [ArgsQueryCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider and requires arguments. It is a wrapper of [useBloc] that creates a [SimpleArgsQueryWithEmptyCubit].
/// Differ from [useArgsQueryCubit] because it uses a custom function to check if the data is empty.
SimpleArgsQueryWithEmptyCubit<TArgs, TOut>
    useArgsQueryWithEmptyCubit<TArgs, TOut>(
  ArgsRequest<TArgs, QueryResult<TOut>> request,
  EmptyChecker<TOut> isEmpty, {
  String loggerTag = 'SimpleArgsQueryWithEmptyCubit',
  RequestMode? requestMode,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () => SimpleArgsQueryWithEmptyCubit<TArgs, TOut>(
      loggerTag,
      request,
      isEmpty,
      requestMode: requestMode,
    ),
    keys: keys,
  );
}
