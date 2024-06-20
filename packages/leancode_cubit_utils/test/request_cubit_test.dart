import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/http_status_codes.dart';
import 'utils/mocked_http_client.dart';
import 'utils/test_request_cubit.dart';

void main() {
  final client = MockedHttpClient();

  setUpAll(() {
    registerFallbackValue(Uri.parse('0'));
    when(
      () => client.get(Uri.parse('0')),
    ).thenAnswer(
      (_) async => http.Response('Result', StatusCode.ok.value),
    );

    when(
      () => client.get(Uri.parse('1')),
    ).thenAnswer(
      (_) async => http.Response('Mapping fails', StatusCode.ok.value),
    );

    when(
      () => client.get(Uri.parse('2')),
    ).thenAnswer(
      (_) async => http.Response('', StatusCode.notFound.value),
    );

    when(
      () => client.get(Uri.parse('3')),
    ).thenAnswer(
      (_) async => http.Response('', StatusCode.badRequest.value),
    );
  });

  group('RequestCubit', () {
    group('request succeeded', () {
      blocTest<TestRequestCubit, RequestState<String, int>>(
        'get() triggers request',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          id: '0',
        ),
        act: (cubit) => cubit.run(),
        verify: (cubit) {
          verify(
            () => client.get(Uri.parse('0')),
          ).called(1);
        },
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestSuccessState when processing succeeds',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          id: '0',
        ),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => <RequestState<String, int>>[
          RequestLoadingState(),
          RequestSuccessState('Mapped Result'),
        ],
      );
    });

    group('refresh', () {
      setUp(() => clearInteractions(client));
      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestRefreshState with the same data when refresh is called',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          id: '0',
        ),
        seed: () => RequestSuccessState('Mapped Result'),
        act: (cubit) => cubit.refresh(),
        expect: () => <RequestState<String, int>>[
          RequestRefreshState('Mapped Result'),
          RequestSuccessState('Mapped Result'),
        ],
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'ignores duplicated refresh calls by default',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          id: '0',
        ),
        act: (cubit) async {
          unawaited(cubit.run());
          await cubit.run();
        },
        verify: (_) {
          verify(
            () => client.get(Uri.parse('0')),
          ).called(1);
        },
        expect: () => <RequestState<String, int>>[
          RequestLoadingState(),
          RequestSuccessState('Mapped Result'),
        ],
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'cancels previous call and starts over when requestMode is replace',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          id: '0',
          requestMode: RequestMode.replace,
        ),
        act: (cubit) async {
          unawaited(cubit.run());
          await cubit.run();
        },
        verify: (cubit) {
          verify(
            () => client.get(Uri.parse('0')),
          ).called(2);
        },
        expect: () => <RequestState<String, int>>[
          RequestLoadingState(),
          RequestSuccessState('Mapped Result'),
        ],
      );
    });

    group('handling errors and exceptions', () {
      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestErrorState when query fails',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          //cubit with argument '2' will fail processing on http request
          id: '2',
        ),
        act: (cubit) => cubit.run(),
        expect: () => [
          isA<RequestLoadingState<String, int>>(),
          isA<RequestErrorState<String, int>>(),
        ],
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestErrorState when request mapping fails',
        build: () => TestRequestCubit(
          'TestRequestCubit',
          client: client,
          //cubit with argument '1' will throw an exception in map()
          id: '1',
        ),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => [
          isA<RequestLoadingState<String, int>>(),
          isA<RequestErrorState<String, int>>(),
        ],
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestErrorState when onQueryError fails',
        build: () => TestRequestCubit(
          'TestQueryCubit',
          client: client,
          //cubit with argument '3' will throw exception on onQueryError
          id: '3',
        ),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => [
          isA<RequestLoadingState<String, int>>(),
          isA<RequestErrorState<String, int>>(),
        ],
      );
    });
  });

  group('ArgsRequestCubit', () {
    clearInteractions(client);
    blocTest<TestArgsRequestCubit, RequestState<String, int>>(
      'calls request() with passed arguments when get() is called',
      build: () => TestArgsRequestCubit(
        'TestArgsRequestCubit',
        client: client,
      ),
      act: (cubit) => cubit.run('0'),
      verify: (_) {
        verify(
          () => client.get(Uri.parse('0')),
        ).called(1);
      },
    );

    blocTest<TestArgsRequestCubit, RequestState<String, int>>(
      'calls refresh with last args when get() was called before',
      build: () => TestArgsRequestCubit(
        'TestArgsRequestCubit',
        client: client,
      ),
      act: (cubit) async {
        await cubit.run('0');
        await cubit.refresh();
      },
      verify: (_) {
        verify(() => client.get(Uri.parse('0'))).called(2);
      },
    );
  });
}
