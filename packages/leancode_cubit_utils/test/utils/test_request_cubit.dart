import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

import 'http_status_codes.dart';

mixin RequestResultHandler<TOut>
    on BaseRequestCubit<http.Response, String, int> {
  @override
  Future<RequestState<String, int>> handleResult(http.Response result) async {
    if (result.statusCode == StatusCode.ok.value) {
      if (result.body.isEmpty) {
        logger.warning('Query success but data is empty');
        return RequestEmptyState(result.body);
      }
      logger.info('Query success. Data: ${result.body}');
      return RequestSuccessState(result.body);
    } else {
      logger.severe('Query error. Status code: ${result.statusCode}');
      try {
        return await handleError(RequestErrorState(error: result.statusCode));
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        return RequestErrorState(exception: e, stackTrace: s);
      }
    }
  }
}

class TestRequestCubit extends RequestCubit<http.Response, String, int>
    with RequestResultHandler<String> {
  TestRequestCubit(
    super.loggerTag, {
    super.requestMode,
    required this.client,
    required this.id,
  });

  final http.Client client;
  final String id;

  @override
  Future<http.Response> request() {
    return client.get(Uri.parse(id));
  }

  @override
  Future<RequestErrorState<String, int>> handleError(
    RequestErrorState<String, int> errorState,
  ) async {
    if (errorState.error == StatusCode.badRequest.value) {
      throw Exception('onQueryError failed');
    } else {
      return errorState;
    }
  }
}

class TestArgsRequestCubit
    extends ArgsRequestCubit<String, http.Response, String, int>
    with RequestResultHandler<String> {
  TestArgsRequestCubit(super.loggerTag, {required this.client});

  final http.Client client;

  @override
  Future<http.Response> request(String args) {
    return client.get(Uri.parse(args));
  }
}

class FakeRequestCubit extends RequestCubit<http.Response, String, int>
    with RequestResultHandler<String> {
  FakeRequestCubit.success() : super('FakeRequestCubit') {
    emit(RequestSuccessState(fakeResult));
  }

  FakeRequestCubit.error() : super('FakeRequestCubit') {
    emit(RequestErrorState(error: 1));
  }

  FakeRequestCubit.empty() : super('FakeRequestCubit') {
    emit(RequestEmptyState(fakeResult));
  }

  FakeRequestCubit.loading() : super('FakeRequestCubit') {
    emit(RequestLoadingState());
  }

  FakeRequestCubit.refresh() : super('FakeRequestCubit') {
    emit(RequestRefreshState(data: fakeResult));
  }

  static const fakeResult = 'Result';

  @override
  Future<http.Response> request() async => http.Response('', 1);
}
