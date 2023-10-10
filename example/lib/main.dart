import 'dart:developer';

import 'package:cqrs/cqrs.dart';
import 'package:example/cqrs/cqrs.dart';
import 'package:example/pages/home_page.dart';
import 'package:example/pages/paginated/paginated_cubit_page.dart';
import 'package:example/pages/query/query_page.dart';
import 'package:flutter/material.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class Routes {
  static const home = '/';
  static const simpleQuery = '/simple-query';
  static const paginatedCubit = '/paginated-cubit';
}

void _setupLogger() {
  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen(
    (record) => log(
      record.message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    ),
  );

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
}

void main() {
  final cqrs = createMockedCqrs();

  _setupLogger();

  runApp(
    Provider<Cqrs>.value(
      value: cqrs,
      child: PaginatedConfigProvider(
        onFirstPageLoading: (context, state) => const Center(
          child: CircularProgressIndicator(),
        ),
        onFirstPageError: (context, error, retry) => Error(
          retry: retry,
          error: error,
        ),
        onNextPageLoading: (context, state) => const Center(
          child: CircularProgressIndicator(),
        ),
        onNextPageError: (context, error, retry) => Error(
          retry: retry,
          error: error,
        ),
        onEmptyState: (context, state) => const Center(child: Text('No items')),
        child: QueryConfigProvider(
          requestMode: RequestMode.replace,
          onLoading: (BuildContext context) =>
              const CircularProgressIndicator(),
          onError: (
            BuildContext context,
            QueryErrorState<dynamic> error,
            VoidCallback? onErrorCallback,
          ) {
            return const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            );
          },
          child: const MainApp(),
        ),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        Routes.home: (_) => const HomePage(),
        Routes.simpleQuery: (_) => const QueryHookScreen(),
        Routes.paginatedCubit: (_) => const PaginatedCubitScreen(),
      },
    );
  }
}

class Error extends StatelessWidget {
  const Error({
    super.key,
    this.retry,
    required this.error,
  });

  final VoidCallback? retry;
  final PaginatedStateError error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      PaginatedStateQueryError(:final error) => error.name,
      PaginatedStateException(:final exception) => exception.toString(),
      _ => '',
    };

    return retry != null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              ElevatedButton(onPressed: retry, child: const Text('Retry')),
            ],
          )
        : Text(message);
  }
}
