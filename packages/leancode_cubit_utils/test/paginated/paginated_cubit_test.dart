import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocked_api.dart';
import 'test_paginated_cubit.dart';

typedef TestPaginatedState = PaginatedState<void, City>;

typedef TestPreRequestPaginatedState = PaginatedState<List<CityType>, City>;

void main() {
  final api = ApiBase();
  final mockedApi = MockedApi();
  final defaultArgs = PaginatedArgs.fromConfig(PaginatedConfigProvider.config);
  group('PaginatedCubit', () {
    setUp(() => clearInteractions(mockedApi));
    group('PaginatedConfig', () {
      test('takes parameters from config when no parameters where passed', () {
        final cubit = TestPaginatedCubit(api);
        expect(cubit.state.args, defaultArgs);
      });

      test('takes parameters from config when parameters where passed', () {
        const firstPageIndex = 1;
        const pageSize = 10;

        final cubit = TestPaginatedCubit(
          api,
          config: PaginatedConfig(firstPageIndex: 1, pageSize: 10),
        );

        expect(cubit.state.args.firstPageIndex, firstPageIndex);
        expect(cubit.state.args.pageSize, pageSize);
        expect(cubit.state.args.pageNumber, firstPageIndex);
      });
    });

    group('getting pages', () {
      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'gets first page when run() ',
        build: () => TestPaginatedCubit(api),
        act: (cubit) => cubit.run(),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.firstPageLoading,
            args: defaultArgs,
          ),
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
          ),
        ],
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'appends next page items to existing items list',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(api),
        act: (cubit) => cubit.fetchNextPage(1),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.nextPageLoading,
            items: api.cities.take(20).toList(),
            args: defaultArgs.copyWith(pageNumber: 1),
            hasNextPage: true,
          ),
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(40).toList(),
            args: defaultArgs.copyWith(pageNumber: 1),
            hasNextPage: true,
          ),
        ],
      );
    });

    group('search', () {
      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'emits state with updated search query',
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit
          ..updateSearchQuery('a')
          ..updateSearchQuery('ab'),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            args: defaultArgs.copyWith(searchQuery: 'a'),
          ),
          PaginatedState(
            args: defaultArgs.copyWith(searchQuery: 'ab'),
          ),
        ],
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'does not search when searchQuery is too short',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit
          ..updateSearchQuery('a')
          ..updateSearchQuery('ab'),
        verify: (_) {
          verifyNever(
            () => mockedApi.getCities(
              any(),
              any(),
              searchQuery: any(
                named: 'searchQuery',
              ),
            ),
          );
        },
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'invokes search with searchQuery as a parameter when searchQuery is long enough',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.updateSearchQuery('abc'),
        verify: (_) {
          verify(
            () => mockedApi.getCities(
              any(),
              any(),
              searchQuery: 'abc',
            ),
          ).called(1);
        },
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'start searching and resets the list when searchQuery is long enough',
        setUp: () {
          when(
            () => mockedApi.getCities(
              any(),
              any(),
              searchQuery: any(named: 'searchQuery'),
            ),
          ).thenAnswer(
            (_) async => QuerySuccess(
              Page<City>(
                cities: api.cities.take(20).toList(),
                hasNextPage: true,
              ),
            ),
          );
        },
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.updateSearchQuery('abc'),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(20).toList(),
            args: defaultArgs.copyWith(searchQuery: 'abc'),
            hasNextPage: true,
          ),
          PaginatedState(
            type: PaginatedStateType.firstPageLoading,
            items: [],
            args: defaultArgs.copyWith(searchQuery: 'abc'),
            hasNextPage: true,
          ),
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(20).toList(),
            args: defaultArgs.copyWith(searchQuery: 'abc'),
            hasNextPage: true,
          ),
        ],
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'gets first page with no searchQuery, when searchQuery length go under the trigger limit',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs.copyWith(searchQuery: 'abc'),
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.updateSearchQuery('ab'),
        verify: (_) {
          verify(
            () => mockedApi.getCities(
              any(),
              any(),
            ),
          ).called(1);
        },
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'invokes search only once when searchQuery changes multiple times in a short time',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs.copyWith(searchQuery: 'abc'),
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) async {
          unawaited(cubit.updateSearchQuery('abc'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          unawaited(cubit.updateSearchQuery('abcd'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          unawaited(cubit.updateSearchQuery('abcde'));
        },
        wait: const Duration(milliseconds: 600),
        verify: (_) {
          verifyNever(
            () => mockedApi.getCities(
              any(),
              any(),
              searchQuery: 'abc',
            ),
          );
          verifyNever(
            () => mockedApi.getCities(
              any(),
              any(),
              searchQuery: 'abcd',
            ),
          );
          verify(
            () => mockedApi.getCities(
              any(),
              any(),
              searchQuery: 'abcde',
            ),
          ).called(1);
        },
      );
    });

    blocTest<TestPaginatedCubit, TestPaginatedState>(
      'searchQuery is passed when next pages are loaded',
      seed: () => PaginatedState(
        type: PaginatedStateType.success,
        items: api.cities.take(20).toList(),
        args: defaultArgs.copyWith(searchQuery: 'abc'),
        hasNextPage: true,
      ),
      build: () => TestPaginatedCubit(mockedApi),
      act: (cubit) => cubit.fetchNextPage(1),
      verify: (_) {
        verify(
          () => mockedApi.getCities(
            1,
            20,
            searchQuery: 'abc',
          ),
        ).called(1);
      },
    );

    group('pre-request', () {
      final preRequest = TestPreRequest(mockedApi);

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'runs pre-request once before the first page is loaded when preRequestMode is once',
        setUp: () {
          when(mockedApi.getTypes).thenAnswer(
            (_) async => const QuerySuccess(CityType.values),
          );
          when(() => mockedApi.getCities(any(), any())).thenAnswer(
            (_) async => QuerySuccess(
              Page(
                cities: api.cities.take(20).toList(),
                hasNextPage: true,
              ),
            ),
          );
        },
        build: () => TestPreRequestPaginatedCubit(
          mockedApi,
          preRequest: preRequest,
        ),
        act: (cubit) async {
          await cubit.run();
          await cubit.run();
        },
        verify: (_) {
          verify(mockedApi.getTypes).called(1);
        },
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'runs pre-request each time first page is loaded when preRequestMode is each',
        build: () => TestPreRequestPaginatedCubit(
          mockedApi,
          preRequest: preRequest,
          config: PaginatedConfig(preRequestMode: PreRequestMode.each),
        ),
        act: (cubit) async {
          unawaited(cubit.run());
          await Future<void>.delayed(const Duration(milliseconds: 100));
          unawaited(cubit.run());
        },
        verify: (_) {
          verify(mockedApi.getTypes).called(2);
        },
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'do not run pre-request when pre-request is null',
        build: () => TestPreRequestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.run(),
        verify: (_) {
          verifyNever(mockedApi.getTypes);
        },
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'pre-request is not run when preRequestMode is each and next page is loaded',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
          data: [],
        ),
        build: () => TestPreRequestPaginatedCubit(
          mockedApi,
          preRequest: preRequest,
          config: PaginatedConfig(preRequestMode: PreRequestMode.each),
        ),
        act: (cubit) => cubit.fetchNextPage(1),
        verify: (_) {
          verifyNever(mockedApi.getTypes);
        },
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'pre-request is re-run when first fails and page is refreshed',
        build: () => TestPreRequestPaginatedCubit(
          mockedApi,
          preRequest: preRequest,
        ),
        act: (cubit) {
          when(mockedApi.getTypes).thenAnswer(
            (_) async => const QueryFailure(QueryError.network),
          );
          cubit.run();
          when(mockedApi.getTypes).thenAnswer(
            (_) async => const QuerySuccess(CityType.values),
          );
          cubit.run();
        },
        verify: (_) {
          verify(mockedApi.getTypes).called(2);
        },
      );
    });

    group('refresh', () {
      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'fetches the first page when refresh() is called',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.refresh(),
        verify: (_) {
          verify(
            () => mockedApi.getCities(0, 20),
          ).called(1);
        },
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'keeps the items when refresh() is called',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        setUp: () {
          when(() => mockedApi.getCities(0, 20)).thenAnswer(
            (_) async => QuerySuccess(
              Page(
                cities: api.cities.take(20).toList(),
                hasNextPage: true,
              ),
            ),
          );
        },
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.refresh(),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.refresh,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
          ),
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
          ),
        ],
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'refreshes first page with searchQuery when searchQuery is long enough',
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs.copyWith(searchQuery: 'abcd'),
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.refresh(),
        verify: (_) {
          verify(
            () => mockedApi.getCities(
              0,
              20,
              searchQuery: 'abcd',
            ),
          ).called(1);
        },
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'cancels previous refresh processing when a new refresh is called within short time',
        setUp: () {
          when(() => mockedApi.getCities(0, 20)).thenAnswer(
            (_) async => QuerySuccess(
              Page(
                cities: api.cities.take(20).toList(),
                hasNextPage: true,
              ),
            ),
          );
        },
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) async {
          unawaited(cubit.refresh());
          unawaited(cubit.refresh());
        },
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.refresh,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
          ),
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
          ),
        ],
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'keeps the data when refresh is processed',
        setUp: () {
          when(() => mockedApi.getCities(0, 20)).thenAnswer(
            (_) async => QuerySuccess(
              Page(
                cities: api.cities.take(20).toList(),
                hasNextPage: true,
              ),
            ),
          );
        },
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
          data: CityType.values,
        ),
        build: () => TestPreRequestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.refresh(),
        expect: () => <TestPreRequestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.refresh,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
            data: CityType.values,
          ),
          PaginatedState(
            type: PaginatedStateType.success,
            items: api.cities.take(20).toList(),
            args: defaultArgs,
            hasNextPage: true,
            data: CityType.values,
          ),
        ],
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'requestPage is called when previous call ends with error',
        setUp: () {
          when(() => mockedApi.getCities(0, 20)).thenAnswer(
            (_) async => QuerySuccess(
              Page(
                cities: api.cities.take(20).toList(),
                hasNextPage: true,
              ),
            ),
          );

          when(mockedApi.getTypes).thenAnswer(
            (_) async => const QuerySuccess(CityType.values),
          );
        },
        build: () => TestPreRequestPaginatedCubit(
          mockedApi,
          preRequest: TestPreRequest(mockedApi),
        ),
        seed: () => PaginatedState(
          type: PaginatedStateType.firstPageError,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          data: CityType.values,
          error: 'error',
        ),
        act: (cubit) => cubit.refresh(),
        verify: (_) {
          verify(() => mockedApi.getCities(0, 20)).called(1);
        },
      );
    });

    group('fails', () {
      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'emits firstPageError when loading first page fails',
        setUp: () {
          when(() => mockedApi.getCities(any(), any())).thenAnswer(
            (_) async => const QueryFailure(QueryError.network),
          );
        },
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.run(),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.firstPageLoading,
            args: defaultArgs,
          ),
          PaginatedState(
            type: PaginatedStateType.firstPageError,
            args: defaultArgs,
            error: QueryError.network,
          ),
        ],
      );

      blocTest<TestPaginatedCubit, TestPaginatedState>(
        'emits nextPageError when loading next page fails',
        setUp: () {
          when(() => mockedApi.getCities(any(), any())).thenAnswer(
            (_) async => const QueryFailure(QueryError.network),
          );
        },
        seed: () => PaginatedState(
          type: PaginatedStateType.success,
          items: api.cities.take(20).toList(),
          args: defaultArgs,
          hasNextPage: true,
        ),
        build: () => TestPaginatedCubit(mockedApi),
        act: (cubit) => cubit.fetchNextPage(1),
        expect: () => <TestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.nextPageLoading,
            items: api.cities.take(20).toList(),
            args: defaultArgs.copyWith(pageNumber: 1),
            hasNextPage: true,
          ),
          PaginatedState(
            type: PaginatedStateType.nextPageError,
            items: api.cities.take(20).toList(),
            args: defaultArgs.copyWith(pageNumber: 1),
            hasNextPage: true,
            error: QueryError.network,
          ),
        ],
      );

      blocTest<TestPreRequestPaginatedCubit, TestPreRequestPaginatedState>(
        'emits firstPageError when pre-request fails',
        setUp: () {
          when(mockedApi.getTypes).thenAnswer(
            (_) async => const QueryFailure(QueryError.network),
          );
        },
        build: () => TestPreRequestPaginatedCubit(
          mockedApi,
          preRequest: TestPreRequest(mockedApi),
        ),
        act: (cubit) => cubit.run(),
        expect: () => <TestPreRequestPaginatedState>[
          PaginatedState(
            type: PaginatedStateType.firstPageLoading,
            args: defaultArgs,
            data: [],
          ),
          PaginatedState(
            type: PaginatedStateType.firstPageError,
            args: defaultArgs,
            error: QueryError.network,
            data: [],
          ),
        ],
      );
    });

    group('calculateHasNextPage', () {
      test('should use pageSize and firstPageIndex from default config', () {
        final cubit = TestPaginatedCubit(mockedApi, config: PaginatedConfig());

        //firstPageIndex = 0
        //pageSize = 20
        final hasNextPage = cubit.calculateHasNextPage(
          pageNumber: 3,
          totalCount: 100,
        );

        expect(hasNextPage, true);
      });

      test('correctly return false when all items were fetched', () {
        final cubit = TestPaginatedCubit(mockedApi, config: PaginatedConfig());

        //firstPageIndex = 0
        //pageSize = 20
        final hasNextPage = cubit.calculateHasNextPage(
          pageNumber: 3,
          totalCount: 60,
        );

        expect(hasNextPage, false);
      });

      test('correctly calculates hasNextPage when pageNumber equals 0', () {
        final cubit = TestPaginatedCubit(mockedApi, config: PaginatedConfig());

        //firstPageIndex = 0
        //pageSize = 20
        final hasNextPage = cubit.calculateHasNextPage(
          pageNumber: 0,
          totalCount: 19,
        );

        expect(hasNextPage, false);
      });
    });
  });
}
