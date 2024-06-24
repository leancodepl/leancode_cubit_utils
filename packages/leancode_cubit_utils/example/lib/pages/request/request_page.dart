import 'dart:convert';

import 'package:example/http/client.dart';
import 'package:example/http/status_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

class UserRequestCubit extends RequestCubit<http.Response, String, User, int> {
  UserRequestCubit(
    this._request,
  ) : super('UserRequestCubit');

  final Request<http.Response> _request;

  @override
  Future<http.Response> request() => _request();

  @override
  User map(String data) =>
      User.fromJson(jsonDecode(data) as Map<String, dynamic>);

  @override
  Future<RequestState<User, int>> handleResult(
    http.Response result,
  ) async {
    if (result.statusCode == StatusCode.ok.value) {
      logger.info('Request success. Data: ${result.body}');
      return RequestSuccessState(map(result.body));
    } else {
      logger.severe('Request error. Status code: ${result.statusCode}');
      try {
        return await handleError(RequestErrorState(error: result.statusCode));
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        return RequestErrorState(exception: e, stackTrace: s);
      }
    }
  }
}

class RequestHookScreen extends StatelessWidget {
  const RequestHookScreen({super.key});

  @override
  Widget build(BuildContext context) => const RequestHookPage();
}

class RequestHookPage extends HookWidget {
  const RequestHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userCubit = useBloc(
      () => UserRequestCubit(
        () => context.read<http.Client>().get(Uri.parse('success')),
      )..run(),
      [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple request page'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: RequestCubitBuilder(
              cubit: userCubit,
              builder: (context, data) => Text('${data.name} ${data.surname}'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: userCubit.refresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => UserRequestCubit(
          () => context.read<http.Client>().get(Uri.parse('success')),
        )..run(),
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
                builder: (context, data) =>
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
