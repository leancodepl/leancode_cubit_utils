import 'dart:convert';

import 'package:example/http/client.dart';
import 'package:example/pages/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class UserRequestCubit extends HttpRequestCubit<User> {
  UserRequestCubit({required super.client}) : super('UserRequestCubit');

  @override
  Future<http.Response> request() => client.get(Uri.parse('success'));

  @override
  User map(String data) =>
      User.fromJson(jsonDecode(data) as Map<String, dynamic>);
}

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) =>
            UserRequestCubit(client: context.read<http.Client>())..run(),
        child: const RequestPage(),
      );
}

class RequestPage extends StatelessWidget {
  const RequestPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Simple request page')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: RequestCubitBuilder(
                cubit: context.read<UserRequestCubit>(),
                onSuccess: (context, data) =>
                    Text('${data.name} ${data.surname}'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: context.read<UserRequestCubit>().refresh,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
}
