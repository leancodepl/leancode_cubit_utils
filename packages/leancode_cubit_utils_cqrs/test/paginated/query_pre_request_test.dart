import 'package:cqrs/cqrs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';

class TestQueryPreRequest extends QueryPreRequest<String, String, String> {
  TestQueryPreRequest({
    required this.mapFunction,
    required this.requestFunction,
    required this.errorHandlerFunction,
  });

  final String Function(
    String res,
    PaginatedState<String, String> state,
  ) mapFunction;

  final Future<QueryResult<String>> Function(
    PaginatedState<String, String> state,
  ) requestFunction;

  PaginatedState<String, String> Function(
    PaginatedState<String, String> state,
  ) errorHandlerFunction;

  @override
  String map(String res, PaginatedState<String, String> state) {
    return mapFunction(res, state);
  }

  @override
  Future<QueryResult<String>> request(PaginatedState<String, String> state) {
    return requestFunction(state);
  }

  @override
  PaginatedState<String, String> handleError(
    PaginatedState<String, String> state,
  ) {
    return errorHandlerFunction(state);
  }
}

void main() {
  final defaultArgs = PaginatedArgs.fromConfig(PaginatedConfigProvider.config);

  group('QueryPreRequest', () {
    test('run returns a state when processing completes without an error',
        () async {
      final preRequest = TestQueryPreRequest(
        mapFunction: (res, state) => res,
        requestFunction: (state) async => const QuerySuccess(''),
        errorHandlerFunction: (state) => state,
      );
      final state = PaginatedState<String, String>(args: defaultArgs, data: '');
      final result = await preRequest.run(state);
      expect(result, isA<PaginatedState<String, String>>());
    });

    test(
        'calls error handler only once when both request and map functions fails',
        () async {
      var errorHandlerCalled = 0;
      final preRequest = TestQueryPreRequest(
        mapFunction: (_, __) => throw Exception(),
        requestFunction: (_) => throw Exception(),
        errorHandlerFunction: (state) {
          errorHandlerCalled++;
          return state;
        },
      );
      final state = PaginatedState<String, String>(args: defaultArgs, data: '');
      await preRequest.run(state);
      expect(errorHandlerCalled, 1);
    });

    test(
        'calls error handler only once when request returns failure and handler throws'
        'an error', () async {
      var errorHandlerCalled = 0;
      final preRequest = TestQueryPreRequest(
        mapFunction: (res, __) => res,
        requestFunction: (_) async => const QueryFailure(QueryError.network),
        errorHandlerFunction: (state) {
          errorHandlerCalled++;
          throw Exception();
        },
      );
      final state = PaginatedState<String, String>(args: defaultArgs, data: '');
      await preRequest.run(state);
      expect(errorHandlerCalled, 1);
    });
  });
}
