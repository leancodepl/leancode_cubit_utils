import 'package:cqrs/cqrs.dart';
import 'package:example/cqrs/cqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_hooks/leancode_hooks.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class UserRequestCubit extends QueryCubit<User, User> {
  UserRequestCubit({
    required this.cqrs,
    required this.userId,
  }) : super('UserRequestCubit');

  final Cqrs cqrs;
  final String userId;

  @override
  Future<QueryResult<User>> request() {
    return cqrs.get(UserQuery(userId: userId));
  }

  @override
  User map(User data) => data;
}

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserRequestCubit(
        cqrs: context.read<Cqrs>(),
        userId: 'success',
      )..get(),
      child: const RequestPage(),
    );
  }
}

class RequestHookScreen extends StatelessWidget {
  const RequestHookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestHookPage();
  }
}

class RequestHookPage extends HookWidget {
  const RequestHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userRequestCubit = useQueryCubit(
      () => context.read<Cqrs>().get(UserQuery(userId: 'success')),
      loggerTag: 'UserRequestCubit',
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
              requestCubit: userRequestCubit,
              builder: (context, data) => Text('${data.name} ${data.surname}'),
            ),
          ),
          ElevatedButton(
            onPressed: userRequestCubit.refresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class RequestPage extends StatelessWidget {
  const RequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple request page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: RequestCubitBuilder(
              requestCubit: context.read<UserRequestCubit>(),
              builder: (context, data) => Text('${data.name} ${data.surname}'),
            ),
          ),
          ElevatedButton(
            onPressed: context.read<UserRequestCubit>().refresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
