import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

/// Implementation of [RequestCubit] created in order to be used by [useRequestCubit].
class SimpleRequestCubit<TRes, TOut, TError>
    extends RequestCubit<TRes, TOut, TOut, TError> {
  /// Creates a new [SimpleRequestCubit].
  SimpleRequestCubit(
    super.loggerTag,
    this._customRequest, {
    super.requestMode,
    required super.resultHandler,
  });

  /// The request to be executed.
  final Request<TRes> _customRequest;

  @override
  Future<TRes> request() => _customRequest();

  @override
  TOut map(TOut data) => data;
}

/// Provides a [RequestCubit] that is automatically disposed without having
/// to use BlocProvider. It is a wrapper of [useBloc] that creates a [SimpleRequestCubit].
SimpleRequestCubit<TRes, TOut, TError> useRequestCubit<TRes, TOut, TError>(
  Request<TRes> request, {
  required ResultHandler<TRes, TOut, TOut, TError> resultHandler,
  String loggerTag = 'SimpleRequestCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () {
      final cubit = SimpleRequestCubit<TRes, TOut, TError>(
        loggerTag,
        request,
        requestMode: requestMode,
        resultHandler: resultHandler,
      );
      if (callOnCreate) {
        cubit.get();
      }
      return cubit;
    },
    keys,
  );
}

/// Implementation of [ArgsRequestCubit] created in order to be used by [useArgsRequestCubit].
class SimpleArgsRequestCubit<TArgs, TRes, TOut, TError>
    extends ArgsRequestCubit<TArgs, TRes, TOut, TOut, TError> {
  /// Creates a new [SimpleArgsRequestCubit].
  SimpleArgsRequestCubit(
    super.loggerTag,
    this._customRequest, {
    super.requestMode,
    required super.resultHandler,
  });

  /// The request to be executed.
  final ArgsRequest<TArgs, TRes> _customRequest;

  @override
  TOut map(TOut data) => data;

  @override
  Future<TRes> request(TArgs args) => _customRequest(args);
}

/// Creates a new [SimpleArgsRequestCubit] with the given [loggerTag], [request] and
/// [requestMode].
SimpleArgsRequestCubit<TArgs, TRes, TOut, TError>
    useArgsRequestCubit<TArgs, TRes, TOut, TError>(
  ArgsRequest<TArgs, TRes> request, {
  required ResultHandler<TRes, TOut, TOut, TError> resultHandler,
  String loggerTag = 'SimpleArgsQueryCubit',
  RequestMode? requestMode,
  List<Object?> keys = const [],
}) {
  return useBloc(
    () => SimpleArgsRequestCubit<TArgs, TRes, TOut, TError>(
      loggerTag,
      request,
      requestMode: requestMode,
      resultHandler: resultHandler,
    ),
    keys,
  );
}
