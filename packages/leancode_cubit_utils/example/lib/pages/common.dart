import 'package:example/http/status_codes.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// Base class for http request cubits.
abstract class HttpRequestCubit<TOut>
    extends RequestCubit<http.Response, String, TOut, int> {
  HttpRequestCubit(super.loggerTag, {required this.client});

  final http.Client client;

  @override
  Future<RequestState<TOut, int>> handleResult(
    http.Response result,
  ) async {
    if (result.statusCode == StatusCode.ok.value) {
      logger.info('Request success. Data: ${result.body}');
      return RequestSuccessState(map(result.body));
    } else {
      logger.severe('Request error. Status code: ${result.statusCode}');
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

/// Base class for http pre-request use cases.
abstract class HttpPreRequest<TData, TItem>
    extends PreRequest<http.Response, String, TData, TItem> {
  @override
  Future<PaginatedState<TData, TItem>> run(
      PaginatedState<TData, TItem> state) async {
    try {
      final result = await request(state);

      if (result.statusCode == StatusCode.ok.value) {
        return state.copyWith(
          data: map(result.body, state),
          preRequestSuccess: true,
        );
      } else {
        try {
          return handleError(state.copyWithError(result.statusCode));
        } catch (e) {
          return state.copyWithError(e);
        }
      }
    } catch (e) {
      try {
        return handleError(state.copyWithError(e));
      } catch (e) {
        return state.copyWithError(e);
      }
    }
  }
}
