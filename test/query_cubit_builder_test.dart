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
    return RequestLayoutConfigProvider(
      onLoading: (context) => const Text('Loading...'),
      onError: (context, error, onErrorCallback) => const Text('Error!'),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }
}

void main() {
  group('RequestCubitBuilder', () {
    final cqrs = MockedCqrs();
    when(
      () => cqrs.get(TestQuery(id: '0')),
    ).thenAnswer(
      (_) async => const QuerySuccess('Result'),
    );

    when(
      () => cqrs.get(TestQuery(id: '1')),
    ).thenAnswer(
      (_) async => const QueryFailure(QueryError.network),
    );

    testWidgets(
        'shows default loading and error widget when no onLoading and onError provided',
        (tester) async {
      final queryCubit = TestArgsQueryCubit('TestQueryCubit', cqrs: cqrs);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            builder: (context, data) => Text(data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Loading...'), findsOneWidget);
      unawaited(queryCubit.get('1'));
      await tester.pump();
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pump();
      expect(find.text('Error!'), findsOneWidget);
    });

    testWidgets('shows custom loading and error widget when provided',
        (tester) async {
      final queryCubit = TestArgsQueryCubit('TestQueryCubit', cqrs: cqrs);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            onLoading: (context) => const Text('Custom loading...'),
            onError: (context, error, retry) => const Text('Custom error!'),
            builder: (context, data) => Text(data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom loading...'), findsOneWidget);
      unawaited(queryCubit.get('1'));
      await tester.pump();
      expect(find.text('Custom loading...'), findsOneWidget);
      await tester.pump();
      expect(find.text('Custom error!'), findsOneWidget);
    });

    testWidgets('shows provided success widget when data loaded',
        (tester) async {
      final queryCubit = TestArgsQueryCubit('TestQueryCubit', cqrs: cqrs);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            builder: (context, data) => Text('Success, data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(queryCubit.get('0'));
      await tester.pumpAndSettle();
      expect(find.text('Success, data: Result'), findsOneWidget);
    });

    testWidgets('keeps showing success widget when data is refreshed',
        (tester) async {
      final queryCubit = TestArgsQueryCubit('TestQueryCubit', cqrs: cqrs);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            builder: (context, data) => Text('Success, data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await queryCubit.get('0');
      await tester.pumpAndSettle();
      expect(find.text('Success, data: Result'), findsOneWidget);
      unawaited(queryCubit.refresh());
      await tester.pump();
      expect(find.text('Success, data: Result'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
