import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cqrs/cqrs.dart';
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
      (invocation) => Future.delayed(
        const Duration(milliseconds: 500),
        () => const QuerySuccess('Result'),
      ),
    );

    when(
      () => cqrs.get(TestQuery(id: '1')),
    ).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 500),
        () => const QuerySuccess('Mapping fails'),
      ),
    );

    when(
      () => cqrs.get(TestQuery(id: '2')),
    ).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 500),
        () => const QueryFailure(QueryError.network),
      ),
    );

    when(
      () => cqrs.get(TestQuery(id: '3')),
    ).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 500),
        () => const QueryFailure(QueryError.unknown),
      ),
    );
  });

  group('QueryCubit', () {
    group('request succeeded', () {
      blocTest<TestQueryCubit, QueryState<String>>(
        'get() triggers request',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        act: (cubit) => cubit.get(),
        wait: Duration.zero,
        verify: (cubit) {
          verify(
            () => cqrs.get(TestQuery(id: '0')),
          ).called(1);
        },
      );

      blocTest<TestQueryCubit, QueryState<String>>(
        'emits QueryErrorSuccess when processing succeeds',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        act: (cubit) => cubit.get(),
        wait: Duration.zero,
        expect: () => <QueryState<String>>[
          QueryLoadingState(),
          QuerySuccessState('Mapped Result'),
        ],
      );
    });

    group('refresh', () {
      setUp(() => clearInteractions(cqrs));
      blocTest<TestQueryCubit, QueryState<String>>(
        'emits QueryRefreshState with the same data when refresh is called',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        seed: () => QuerySuccessState('Mapped Result'),
        act: (cubit) => cubit.refresh(),
        expect: () => <QueryState<String>>[
          QueryRefreshState('Mapped Result'),
          QuerySuccessState('Mapped Result'),
        ],
      );

      blocTest<TestQueryCubit, QueryState<String>>(
        'ignores duplicated refresh calls by default',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
        ),
        act: (cubit) async {
          unawaited(cubit.get());
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await cubit.get();
        },
        verify: (_) {
          verify(
            () => cqrs.get(TestQuery(id: '0')),
          ).called(1);
        },
        wait: const Duration(milliseconds: 400),
        expect: () => <QueryState<String>>[
          QueryLoadingState(),
          QuerySuccessState('Mapped Result'),
        ],
      );

      blocTest<TestQueryCubit, QueryState<String>>(
        'cancels previous call and starts over when requestMode is replace',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          id: '0',
          requestMode: RequestMode.replace,
        ),
        act: (cubit) async {
          unawaited(cubit.get());
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await cubit.get();
        },
        verify: (cubit) {
          verify(
            () => cqrs.get(TestQuery(id: '0')),
          ).called(2);
        },
        wait: const Duration(milliseconds: 400),
        expect: () => <QueryState<String>>[
          QueryLoadingState(),
          QuerySuccessState('Mapped Result'),
        ],
      );
    });

    group('handling errors and exceptions', () {
      blocTest<TestQueryCubit, QueryState<String>>(
        'emits QueryErrorState when query fails',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          //cubit with argument '2' will fail processing on cqrs request
          id: '2',
        ),
        act: (cubit) => cubit.get(),
        wait: Duration.zero,
        expect: () => [
          isA<QueryLoadingState<String>>(),
          isA<QueryErrorState<String>>(),
        ],
      );

      blocTest<TestQueryCubit, QueryState<String>>(
        'emits QueryErrorState when request mapping fails',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          //cubit with argument '1' will throw an exception in map()
          id: '1',
        ),
        act: (cubit) => cubit.get(),
        wait: Duration.zero,
        expect: () => [
          isA<QueryLoadingState<String>>(),
          isA<QueryErrorState<String>>(),
        ],
      );

      blocTest<TestQueryCubit, QueryState<String>>(
        'emits QueryErrorState when onQueryError fails',
        build: () => TestQueryCubit(
          'TestQueryCubit',
          cqrs: cqrs,
          //cubit with argument '3' will throw exception on onQueryError
          id: '3',
        ),
        act: (cubit) => cubit.get(),
        wait: Duration.zero,
        expect: () => [
          isA<QueryLoadingState<String>>(),
          isA<QueryErrorState<String>>(),
        ],
      );
    });
  });

  group('ArgsQueryCubit', () {
    blocTest<TestArgsQueryCubit, QueryState<String>>(
      'calls request() with passed arguments when get() is called',
      build: () => TestArgsQueryCubit(
        'TestArgsQueryCubit',
        cqrs: cqrs,
      ),
      act: (cubit) => cubit.get('0'),
      verify: (_) {
        verify(
          () => cqrs.get(TestQuery(id: '0')),
        ).called(1);
      },
    );

    blocTest<TestArgsQueryCubit, QueryState<String>>(
      'do not refresh the call when get() was not called before',
      build: () => TestArgsQueryCubit(
        'TestArgsQueryCubit',
        cqrs: cqrs,
      ),
      act: (cubit) => cubit.refresh(),
      verify: (_) {
        verifyNever(() => cqrs.get(any()));
      },
    );

    blocTest<TestArgsQueryCubit, QueryState<String>>(
      'calls refresh with last args when get() was called before',
      build: () => TestArgsQueryCubit(
        'TestArgsQueryCubit',
        cqrs: cqrs,
      ),
      act: (cubit) async {
        await cubit.get('0');
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await cubit.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      verify: (_) {
        verify(() => cqrs.get(TestQuery(id: '0'))).called(2);
      },
    );
  });
}
