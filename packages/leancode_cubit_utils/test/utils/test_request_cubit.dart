import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

import 'http_status_codes.dart';

mixin RequestResultHandler<TOut>
    on BaseRequestCubit<http.Response, String, TOut, int> {
  @override
  Future<RequestState<TOut, int>> handleResult(http.Response result) async {
    if (result.statusCode == StatusCode.ok.value) {
      final data = map(result.body);
      if (isEmpty(data)) {
        logger.warning('Query success but data is empty');
        return RequestEmptyState();
      }
      logger.info('Query success. Data: ${result.body}');
      return RequestSuccessState(data);
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

class TestRequestCubit extends RequestCubit<http.Response, String, String, int>
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
  String map(String data) {
    if (data == 'Mapping fails') {
      throw Exception('Mapping failed');
    }
    return 'Mapped $data';
  }

  @override
  bool isEmpty(String data) {
    return data.isEmpty;
  }

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
    extends ArgsRequestCubit<String, http.Response, String, String, int>
    with RequestResultHandler<String> {
  TestArgsRequestCubit(super.loggerTag, {required this.client});

  final http.Client client;

  @override
  String map(String data) => data;

  @override
  bool isEmpty(String data) => data.isEmpty;

  @override
  Future<http.Response> request(String args) {
    return client.get(Uri.parse(args));
  }
}
