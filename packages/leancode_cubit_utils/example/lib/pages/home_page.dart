import 'package:example/main.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    void pushNamed(String routeName) {
      Navigator.of(context).pushNamed(routeName);
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => pushNamed(Routes.simpleRequest),
              child: const Text('Simple request page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => pushNamed(Routes.paginatedCubit),
              child: const Text('Paginated cubit page'),
            ),
          ],
        ),
      ),
    );
  }
}
