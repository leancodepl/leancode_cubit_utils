import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/http_status_codes.dart';
import 'utils/mocked_http_client.dart';
import 'utils/test_request_cubit.dart';

class _DelayedResultCubit extends RequestCubit<String, String, Object?> {
  _DelayedResultCubit({required this.resultState})
    : super('_DelayedResultCubit');

  final Completer<RequestState<String, Object?>> resultState;
  final handleResultStarted = Completer<void>();

  @override
  Future<String> request() async => 'Result';

  @override
  Future<RequestState<String, Object?>> handleResult(String result) {
    if (!handleResultStarted.isCompleted) {
      handleResultStarted.complete();
    }

    return resultState.future;
  }
}

void main() {
  final client = MockedHttpClient();

  setUpAll(() {
    registerFallbackValue(Uri.parse('0'));
    when(
      () => client.get(Uri.parse('0')),
    ).thenAnswer((_) async => http.Response('Result', StatusCode.ok.value));

    when(
      () => client.get(Uri.parse('2')),
    ).thenAnswer((_) async => http.Response('', StatusCode.notFound.value));

    when(
      () => client.get(Uri.parse('3')),
    ).thenAnswer((_) async => http.Response('', StatusCode.badRequest.value));
  });

  group('RequestCubit', () {
    group('request succeeded', () {
      blocTest<TestRequestCubit, RequestState<String, int>>(
        'get() triggers request',
        build: () =>
            TestRequestCubit('TestRequestCubit', client: client, id: '0'),
        act: (cubit) => cubit.run(),
        verify: (cubit) {
          verify(() => client.get(Uri.parse('0'))).called(1);
        },
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestSuccessState when processing succeeds',
        build: () =>
            TestRequestCubit('TestRequestCubit', client: client, id: '0'),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => <RequestState<String, int>>[
          RequestLoadingState(),
          RequestSuccessState('Result'),
        ],
      );
    });

    group('refresh', () {
      setUp(() => clearInteractions(client));
      blocTest<TestRequestCubit, RequestState<String, int>>(
        'emits RequestRefreshingState with the same data when refresh is called',
        build: () =>
            TestRequestCubit('TestRequestCubit', client: client, id: '0'),
        seed: () => RequestSuccessState('Result'),
        act: (cubit) => cubit.refresh(),
        expect: () => <RequestState<String, int>>[
          RequestRefreshingState('Result'),
          RequestSuccessState('Result'),
        ],
      );

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'ignores duplicated refresh calls by default',
        build: () =>
            TestRequestCubit('TestRequestCubit', client: client, id: '0'),
        act: (cubit) async {
          unawaited(cubit.run());
          await cubit.run();
        },
        verify: (_) {
          verify(() => client.get(Uri.parse('0'))).called(1);
        },
        expect: () => <RequestState<String, int>>[
          RequestLoadingState(),
          RequestSuccessState('Result'),
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
          verify(() => client.get(Uri.parse('0'))).called(2);
        },
        expect: () => <RequestState<String, int>>[
          RequestLoadingState(),
          RequestSuccessState('Result'),
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

    group('close', () {
      late Completer<http.Response> request;

      blocTest<TestRequestCubit, RequestState<String, int>>(
        'cancels an ongoing request without emitting after close',
        setUp: () {
          request = Completer<http.Response>();
          when(
            () => client.get(Uri.parse('delayed')),
          ).thenAnswer((_) => request.future);
        },
        build: () =>
            TestRequestCubit('TestRequestCubit', client: client, id: 'delayed'),
        act: (cubit) async {
          final runFuture = cubit.run();
          await pumpEventQueue();
          await cubit.close();
          request.complete(http.Response('Result', StatusCode.ok.value));
          await runFuture;
        },
        expect: () => <RequestState<String, int>>[RequestLoadingState()],
      );

      blocTest<_DelayedResultCubit, RequestState<String, Object?>>(
        'does not emit when closed while handling a result',
        build: () => _DelayedResultCubit(
          resultState: Completer<RequestState<String, Object?>>(),
        ),
        act: (cubit) async {
          final runFuture = cubit.run();
          await cubit.handleResultStarted.future;
          await cubit.close();
          cubit.resultState.complete(RequestSuccessState('Result'));
          await runFuture;
        },
        expect: () => <RequestState<String, Object?>>[RequestLoadingState()],
      );
    });
  });

  group('ArgsRequestCubit', () {
    clearInteractions(client);
    blocTest<TestArgsRequestCubit, RequestState<String, int>>(
      'calls request() with passed arguments when get() is called',
      build: () => TestArgsRequestCubit('TestArgsRequestCubit', client: client),
      act: (cubit) => cubit.run('0'),
      verify: (_) {
        verify(() => client.get(Uri.parse('0'))).called(1);
      },
    );

    blocTest<TestArgsRequestCubit, RequestState<String, int>>(
      'calls refresh with last args when get() was called before',
      build: () => TestArgsRequestCubit('TestArgsRequestCubit', client: client),
      act: (cubit) async {
        await cubit.run('0');
        await cubit.refresh();
      },
      verify: (_) {
        verify(() => client.get(Uri.parse('0'))).called(2);
      },
    );
  });

  group('RequestState.map', () {
    test('maps RequestInitialState to initial when provided', () {
      final state = RequestInitialState<String, int>();

      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Initial');
    });

    test('maps RequestInitialState to loading when initial not provided', () {
      final state = RequestInitialState<String, int>();

      final result = state.map(
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Loading');
    });

    test('maps RequestLoadingState to loading', () {
      final state = RequestLoadingState<String, int>();

      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Loading');
    });

    test('maps RequestSuccessState to success', () {
      final state = RequestSuccessState<String, int>('test data');

      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Success');
    });

    test('maps RequestErrorState to error', () {
      final state = RequestErrorState<String, int>(
        error: 123,
        exception: 'Kaboom!',
        stackTrace: StackTrace.empty,
      );

      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Error');
    });

    test('maps RequestRefreshingState to refreshing when provided', () {
      final state = RequestRefreshingState<String, int>('refreshing data');

      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Refreshing');
    });

    test(
      'maps RequestRefreshingState to success when refreshing not provided',
      () {
        final state = RequestRefreshingState<String, int>('refreshing data');

        final result = state.map(
          initial: () => 'Initial',
          loading: () => 'Loading',
          success: (_) => 'Success',
          error: (_, _, _) => 'Error',
          empty: (_) => 'Empty',
        );

        expect(result, 'Success');
      },
    );

    test('maps RequestEmptyState to empty when provided', () {
      final state = RequestEmptyState<String?, int>(null);
      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
        empty: (_) => 'Empty',
      );

      expect(result, 'Empty');
    });

    test('maps RequestEmptyState to success when empty not provided', () {
      final state = RequestEmptyState<String?, int>('empty data');
      final result = state.map(
        initial: () => 'Initial',
        loading: () => 'Loading',
        success: (_) => 'Success',
        error: (_, _, _) => 'Error',
        refreshing: (_) => 'Refreshing',
      );

      expect(result, 'Success');
    });
  });
}
