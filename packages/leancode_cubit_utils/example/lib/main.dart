import 'dart:developer';

import 'package:example/http/client.dart';
import 'package:example/pages/home_page.dart';
import 'package:example/pages/paginated/paginated_cubit_page.dart';
import 'package:example/pages/request/request_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class Routes {
  static const home = '/';
  static const simpleRequest = '/simple-request';
  static const simpleRequestHook = '/simple-request-hook';
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
  final client = createMockedHttpClient();

  _setupLogger();

  runApp(
    Provider<http.Client>.value(
      value: client,
      child: PaginatedLayoutConfigProvider(
        onFirstPageLoading: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        onFirstPageError: (context, error, retry) => Error(
          retry: retry,
          error: error,
        ),
        onNextPageLoading: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        onNextPageError: (context, error, retry) => Error(
          retry: retry,
          error: error,
        ),
        onEmptyState: (context) => const Center(child: Text('No items')),
        child: RequestLayoutConfigProvider(
          requestMode: RequestMode.replace,
          onLoading: (BuildContext context) =>
              const CircularProgressIndicator(),
          onError: (
            BuildContext context,
            RequestErrorState<dynamic, dynamic> error,
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
        Routes.simpleRequest: (_) => const RequestScreen(),
        Routes.simpleRequestHook: (_) => const RequestHookScreen(),
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
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return retry != null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              ElevatedButton(onPressed: retry, child: const Text('Retry')),
            ],
          )
        : Text(error.toString());
  }
}
