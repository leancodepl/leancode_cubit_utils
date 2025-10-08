import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

import '../utils/http_status_codes.dart';

class TestPreRequest extends PreRequest<http.Response, String, String, String> {
  TestPreRequest({
    required this.mapFunction,
    required this.requestFunction,
    required this.errorHandlerFunction,
  });

  final String Function(String res, PaginatedState<String, String> state)
  mapFunction;

  final Future<http.Response> Function(PaginatedState<String, String> state)
  requestFunction;

  PaginatedState<String, String> Function(PaginatedState<String, String> state)
  errorHandlerFunction;

  @override
  String map(String res, PaginatedState<String, String> state) {
    return mapFunction(res, state);
  }

  @override
  Future<http.Response> request(PaginatedState<String, String> state) {
    return requestFunction(state);
  }

  @override
  PaginatedState<String, String> handleError(
    PaginatedState<String, String> state,
  ) {
    return errorHandlerFunction(state);
  }

  @override
  Future<PaginatedState<String, String>> run(
    PaginatedState<String, String> state,
  ) async {
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

void main() {
  final defaultArgs = PaginatedArgs.fromConfig(PaginatedConfigProvider.config);

  group('PreRequest', () {
    test(
      'run returns a state when processing completes without an error',
      () async {
        final preRequest = TestPreRequest(
          mapFunction: (res, state) => res,
          requestFunction: (state) async =>
              http.Response('', StatusCode.ok.value),
          errorHandlerFunction: (state) => state,
        );
        final state = PaginatedState<String, String>(
          args: defaultArgs,
          data: '',
        );
        final result = await preRequest.run(state);
        expect(result, isA<PaginatedState<String, String>>());
      },
    );

    test(
      'calls error handler only once when both request and map functions fails',
      () async {
        var errorHandlerCalled = 0;
        final preRequest = TestPreRequest(
          mapFunction: (_, _) => throw Exception(),
          requestFunction: (_) => throw Exception(),
          errorHandlerFunction: (state) {
            errorHandlerCalled++;
            return state;
          },
        );
        final state = PaginatedState<String, String>(
          args: defaultArgs,
          data: '',
        );
        await preRequest.run(state);
        expect(errorHandlerCalled, 1);
      },
    );

    test(
      'calls error handler only once when request returns failure and handler throws'
      'an error',
      () async {
        var errorHandlerCalled = 0;
        final preRequest = TestPreRequest(
          mapFunction: (res, _) => res,
          requestFunction: (_) async =>
              http.Response('', StatusCode.notFound.value),
          errorHandlerFunction: (state) {
            errorHandlerCalled++;
            throw Exception();
          },
        );
        final state = PaginatedState<String, String>(
          args: defaultArgs,
          data: '',
        );
        await preRequest.run(state);
        expect(errorHandlerCalled, 1);
      },
    );
  });
}
