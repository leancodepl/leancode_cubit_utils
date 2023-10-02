import 'dart:async';

import 'package:cqrs/cqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/mocked_cqrs.dart';
import 'utils/test_query.dart';
import 'utils/test_query_cubit.dart';

class TestPage extends StatelessWidget {
  const TestPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return QueryConfigProvider(
      onLoading: (context) => const Text('Loading...'),
      onError: (context, error) => const Text('Error!'),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }
}

void main() {
  group('QueryCubitBuilder', () {
    final cqrs = MockedCqrs();
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
        () => const QueryFailure(QueryError.network),
      ),
    );

    final queryCubit = TestArgsQueryCubit(
      'TestQueryCubit',
      cqrs: cqrs,
    );
    testWidgets(
        'shows default loading and error widget when no onLoading and onError provided',
        (tester) async {
      await tester.pumpWidget(
        TestPage(
          child: QueryCubitBuilder<String>(
            queryCubit: queryCubit,
            builder: (context, data) => Text(data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Loading...'), findsOneWidget);
      unawaited(queryCubit.get('1'));
      await tester.pumpAndSettle();
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Error!'), findsOneWidget);
    });

    testWidgets('shows custom loading and error widget when provided',
        (tester) async {
      await tester.pumpWidget(
        TestPage(
          child: QueryCubitBuilder<String>(
            queryCubit: queryCubit,
            onLoading: (context) => const Text('Custom loading...'),
            onError: (context, error, retry) => const Text('Custom error!'),
            builder: (context, data) => Text(data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom loading...'), findsOneWidget);
      unawaited(queryCubit.get('1'));
      await tester.pumpAndSettle();
      expect(find.text('Custom loading...'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Custom error!'), findsOneWidget);
    });

    testWidgets('shows provided success widget when data loaded',
        (tester) async {
      await tester.pumpWidget(
        TestPage(
          child: QueryCubitBuilder<String>(
            queryCubit: queryCubit,
            builder: (context, data) => Text('Success, data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(queryCubit.get('0'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      expect(find.text('Success, data: Result'), findsOneWidget);
    });

    testWidgets('keeps showing success widget when data is refreshed',
        (tester) async {
      await tester.pumpWidget(
        TestPage(
          child: QueryCubitBuilder<String>(
            queryCubit: queryCubit,
            builder: (context, data) => Text('Success, data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(queryCubit.get('0'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      expect(find.text('Success, data: Result'), findsOneWidget);
      unawaited(queryCubit.refresh());
      await tester.pumpAndSettle();
      expect(find.text('Success, data: Result'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
    });
  });
}
