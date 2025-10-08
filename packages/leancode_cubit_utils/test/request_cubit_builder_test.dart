import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/http_status_codes.dart';
import 'utils/mocked_http_client.dart';
import 'utils/test_request_cubit.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RequestLayoutConfigProvider(
      onLoading: (context) => const Text('Loading...'),
      onEmpty: (context) => const Text('Empty!'),
      onError: (context, error, onErrorCallback) => const Text('Error!'),
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }
}

void main() {
  group('RequestCubitBuilder', () {
    final client = MockedHttpClient();
    when(
      () => client.get(Uri.parse('0')),
    ).thenAnswer((_) async => http.Response('Result', StatusCode.ok.value));

    when(
      () => client.get(Uri.parse('1')),
    ).thenAnswer((_) async => http.Response('', StatusCode.badRequest.value));

    when(
      () => client.get(Uri.parse('2')),
    ).thenAnswer((_) async => http.Response('', StatusCode.ok.value));

    testWidgets(
      'shows default loading and error widget when no onLoading and onError provided',
      (tester) async {
        final queryCubit = TestArgsRequestCubit(
          'TestQueryCubit',
          client: client,
        );

        await tester.pumpWidget(
          TestPage(
            child: RequestCubitBuilder(
              cubit: queryCubit,
              onSuccess: (context, data) => Text(data),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Loading...'), findsOneWidget);
        unawaited(queryCubit.run('1'));
        await tester.pump();
        expect(find.text('Loading...'), findsOneWidget);
        await tester.pump();
        expect(find.text('Error!'), findsOneWidget);
      },
    );

    testWidgets(
      'shows default loading and empty widget when no onLoading and onEmpty provided',
      (tester) async {
        final queryCubit = TestArgsRequestCubit(
          'TestQueryCubit',
          client: client,
        );

        await tester.pumpWidget(
          TestPage(
            child: RequestCubitBuilder(
              cubit: queryCubit,
              onSuccess: (context, data) => Text(data),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Loading...'), findsOneWidget);
        unawaited(queryCubit.run('2'));
        await tester.pump();
        expect(find.text('Loading...'), findsOneWidget);
        await tester.pump();
        expect(find.text('Empty!'), findsOneWidget);
      },
    );

    testWidgets('shows custom loading and error widget when provided', (
      tester,
    ) async {
      final queryCubit = TestArgsRequestCubit('TestQueryCubit', client: client);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            onLoading: (context) => const Text('Custom loading...'),
            onError: (context, error, retry) => const Text('Custom error!'),
            onSuccess: (context, data) => Text(data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom loading...'), findsOneWidget);
      unawaited(queryCubit.run('1'));
      await tester.pump();
      expect(find.text('Custom loading...'), findsOneWidget);
      await tester.pump();
      expect(find.text('Custom error!'), findsOneWidget);
    });

    testWidgets('shows provided success widget when data loaded', (
      tester,
    ) async {
      final queryCubit = TestArgsRequestCubit('TestQueryCubit', client: client);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            onSuccess: (context, data) => Text('Success, data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(queryCubit.run('0'));
      await tester.pumpAndSettle();
      expect(find.text('Success, data: Result'), findsOneWidget);
    });

    testWidgets('keeps showing success widget when data is refreshed', (
      tester,
    ) async {
      final queryCubit = TestArgsRequestCubit('TestQueryCubit', client: client);

      await tester.pumpWidget(
        TestPage(
          child: RequestCubitBuilder(
            cubit: queryCubit,
            onSuccess: (context, data) => Text('Success, data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await queryCubit.run('0');
      await tester.pumpAndSettle();
      expect(find.text('Success, data: Result'), findsOneWidget);
      unawaited(queryCubit.refresh());
      await tester.pump();
      expect(find.text('Success, data: Result'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
