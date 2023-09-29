import 'dart:developer';

import 'package:example/cqrs/cqrs.dart';
import 'package:example/pages/home_page.dart';
import 'package:example/pages/paginated_cubit_page.dart';
import 'package:example/pages/simple_query_page.dart';
import 'package:flutter/material.dart';
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
    Provider(
      create: (context) => cqrs,
      child: const MainApp(),
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
        Routes.simpleQuery: (_) => const SimpleQueryScreen1(),
        Routes.paginatedCubit: (_) => const PaginatedCubitPage(),
      },
    );
  }
}
