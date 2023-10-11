import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

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
