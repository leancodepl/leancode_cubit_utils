import 'package:cqrs/cqrs.dart';
import 'package:example/cqrs/cqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_hooks/leancode_hooks.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class UserQueryCubit extends QueryCubit<User, User> {
  UserQueryCubit({
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

class QueryScreen extends StatelessWidget {
  const QueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserQueryCubit(
        cqrs: context.read<Cqrs>(),
        userId: 'success',
      )..get(),
      child: const QueryPage(),
    );
  }
}

class QueryPage extends StatelessWidget {
  const QueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple request page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: RequestCubitBuilder(
              requestCubit: context.read<UserQueryCubit>(),
              builder: (context, data) => Text('${data.name} ${data.surname}'),
            ),
          ),
          ElevatedButton(
            onPressed: context.read<UserQueryCubit>().refresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class QueryHookScreen extends StatelessWidget {
  const QueryHookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QueryHookPage();
  }
}

class QueryHookPage extends HookWidget {
  const QueryHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userCubit = useQueryCubit(
      () => context.read<Cqrs>().get(UserQuery(userId: 'success')),
      loggerTag: 'UserQueryCubit',
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
              requestCubit: userCubit,
              builder: (context, data) => Text('${data.name} ${data.surname}'),
            ),
          ),
          ElevatedButton(
            onPressed: userCubit.refresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
