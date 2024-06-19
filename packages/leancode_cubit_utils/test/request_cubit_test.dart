import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/mocked_cqrs.dart';
import 'utils/test_query.dart';
import 'utils/test_query_cubit.dart';

void main() {
  final cqrs = MockedCqrs();

  setUpAll(() {
    registerFallbackValue(TestQuery(id: '0'));
    when(
      () => cqrs.get(TestQuery(id: '0')),
    ).thenAnswer(
      (_) async => const QuerySuccess('Result'),
    );

    when(
      () => cqrs.get(TestQuery(id: '1')),
    ).thenAnswer(
      (_) async => const QuerySuccess('Mapping fails'),
    );

    when(
      () => cqrs.get(TestQuery(id: '2')),
    ).thenAnswer(
      (_) async => const QueryFailure(QueryError.network),
    );

    when(
      () => cqrs.get(TestQuery(id: '3')),
    ).thenAnswer(
      (_) async => const QueryFailure(QueryError.unknown),
    );
  });

  group('QueryCubit', () {
    group('request succeeded', () {
      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'get() triggers request',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        act: (cubit) => cubit.run(),
        verify: (cubit) {
          verify(
            () => cqrs.get(TestQuery(id: '0')),
          ).called(1);
        },
      );

      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'emits QueryErrorSuccess when processing succeeds',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => <RequestState<String, QueryError>>[
          RequestLoadingState(),
          RequestSuccessState('Mapped Result'),
        ],
      );
    });

    group('refresh', () {
      setUp(() => clearInteractions(cqrs));
      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'emits QueryRefreshState with the same data when refresh is called',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        seed: () => RequestSuccessState('Mapped Result'),
        act: (cubit) => cubit.refresh(),
        expect: () => <RequestState<String, QueryError>>[
          RequestRefreshState('Mapped Result'),
          RequestSuccessState('Mapped Result'),
        ],
      );

      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'ignores duplicated refresh calls by default',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        act: (cubit) async {
          unawaited(cubit.run());
          await cubit.run();
        },
        verify: (_) {
          verify(
            () => cqrs.get(TestQuery(id: '0')),
          ).called(1);
        },
        expect: () => <RequestState<String, QueryError>>[
          RequestLoadingState(),
          RequestSuccessState('Mapped Result'),
        ],
      );

      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'cancels previous call and starts over when requestMode is replace',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
          requestMode: RequestMode.replace,
        ),
        act: (cubit) async {
          unawaited(cubit.run());
          await cubit.run();
        },
        verify: (cubit) {
          verify(
            () => cqrs.get(TestQuery(id: '0')),
          ).called(2);
        },
        expect: () => <RequestState<String, QueryError>>[
          RequestLoadingState(),
          RequestSuccessState('Mapped Result'),
        ],
      );
    });

    group('handling errors and exceptions', () {
      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'emits QueryErrorState when query fails',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          //cubit with argument '2' will fail processing on cqrs request
          id: '2',
        ),
        act: (cubit) => cubit.run(),
        expect: () => [
          isA<RequestLoadingState<String, QueryError>>(),
          isA<RequestErrorState<String, QueryError>>(),
        ],
      );

      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'emits QueryErrorState when request mapping fails',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          //cubit with argument '1' will throw an exception in map()
          id: '1',
        ),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => [
          isA<RequestLoadingState<String, QueryError>>(),
          isA<RequestErrorState<String, QueryError>>(),
        ],
      );

      blocTest<TestQueryCubit, RequestState<String, QueryError>>(
        'emits QueryErrorState when onQueryError fails',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          //cubit with argument '3' will throw exception on onQueryError
          id: '3',
        ),
        act: (cubit) => cubit.run(),
        wait: Duration.zero,
        expect: () => [
          isA<RequestLoadingState<String, QueryError>>(),
          isA<RequestErrorState<String, QueryError>>(),
        ],
      );
    });
  });

  group('ArgsQueryCubit', () {
    clearInteractions(cqrs);
    blocTest<TestArgsQueryCubit, RequestState<String, QueryError>>(
      'calls request() with passed arguments when get() is called',
      build: () => TestArgsQueryCubit(
        'TestArgsQueryCubit',
        cqrs: cqrs,
      ),
      act: (cubit) => cubit.run('0'),
      verify: (_) {
        verify(
          () => cqrs.get(TestQuery(id: '0')),
        ).called(1);
      },
    );

    blocTest<TestArgsQueryCubit, RequestState<String, QueryError>>(
      'calls refresh with last args when get() was called before',
      build: () => TestArgsQueryCubit(
        'TestArgsQueryCubit',
        cqrs: cqrs,
      ),
      act: (cubit) async {
        await cubit.run('0');
        await cubit.refresh();
      },
      verify: (_) {
        verify(() => cqrs.get(TestQuery(id: '0'))).called(2);
      },
    );
  });
}
