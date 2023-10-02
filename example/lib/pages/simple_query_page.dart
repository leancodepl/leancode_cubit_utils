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
  }) : super('UserQueryCubit');

  final Cqrs cqrs;
  final String userId;

  @override
  User map(User data) => data;

  @override
  Future<QueryResult<User>> request() {
    return cqrs.get(UserQuery(userId: userId));
  }
}

class SimpleQueryScreen extends StatelessWidget {
  const SimpleQueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserQueryCubit(
        cqrs: context.read<Cqrs>(),
        userId: 'success',
      )..get(),
      child: const SimpleQueryPage(),
    );
  }
}

class SimpleQueryHookScreen extends StatelessWidget {
  const SimpleQueryHookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleQueryHookPage();
  }
}

class SimpleQueryHookPage extends HookWidget {
  const SimpleQueryHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userQueryCubit = useQueryCubit<User>(
      () => context.read<Cqrs>().get(UserQuery(userId: 'success')),
      loggerTag: 'UserQueryCubit',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple query page'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: QueryCubitBuilder<User>(
              queryCubit: userQueryCubit,
              builder: (context, data) => Text('${data.name} ${data.surname}'),
            ),
          ),
          ElevatedButton(
            onPressed: userQueryCubit.refresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class SimpleQueryPage extends StatelessWidget {
  const SimpleQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple query page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: QueryCubitBuilder<User>(
              queryCubit: context.read<UserQueryCubit>(),
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
