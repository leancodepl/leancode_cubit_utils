import 'package:cqrs/cqrs.dart';
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
RequestCubit<TRes, TOut, TOut, TError> useRequestCubit<TRes, TOut, TError>(
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

/// Provides a [RequestCubit] specialized for [QueryResult] that is automatically disposed without having
/// to use BlocProvider. It is a wrapper of [useRequestCubit] that creates a [SimpleRequestCubit].
RequestCubit<QueryResult<TOut>, TOut, TOut, QueryError> useQueryCubit<TOut>(
  Request<QueryResult<TOut>> request, {
  String loggerTag = 'SimpleQueryCubit',
  RequestMode? requestMode,
  bool callOnCreate = true,
  List<Object?> keys = const [],
}) {
  return useRequestCubit(
    request,
    loggerTag: loggerTag,
    requestMode: requestMode,
    resultHandler: queryResultHandler<TOut, TOut>,
    callOnCreate: callOnCreate,
    keys: keys,
  );
}
