import 'package:flutter/material.dart';

class SimpleQueryScreen extends StatelessWidget {
  const SimpleQueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleQueryPage();
  }
}

class SimpleQueryPage extends StatelessWidget {
  const SimpleQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple query page')),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}
