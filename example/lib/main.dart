import 'package:example/cqrs/cqrs.dart';
import 'package:example/pages/home_page.dart';
import 'package:example/pages/paginated_cubit_page.dart';
import 'package:example/pages/simple_query_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Routes {
  static const home = '/';
  static const simpleQuery = '/simple-query';
  static const paginatedCubit = '/paginated-cubit';
}

void main() {
  final cqrs = createMockedCqrs();

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
        Routes.simpleQuery: (_) => const SimpleQueryScreen(),
        Routes.paginatedCubit: (_) => const PaginatedCubitPage(),
      },
    );
  }
}
