import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
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

/// Creates a new [SimpleRequestCubit] with the given [loggerTag], [request] and
/// [requestMode].
RequestCubit<TRes, TOut, TOut, TError> useRequestCubit<TRes, TOut, TError>(
  Request<TRes> request, {
  required ResultHandler<TRes, TOut, TError> resultHandler,
  String loggerTag = 'SimpleQueryCubit',
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
