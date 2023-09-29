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

  final AppCqrs cqrs;
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
        cqrs: context.read<AppCqrs>(),
        userId: 'success',
      ),
      child: const SimpleQueryPage(),
    );
  }
}

class SimpleQueryScreen1 extends HookWidget {
  const SimpleQueryScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final userQueryCubit = useQueryCubit<User, User>(
      loggerTag: 'UserQueryCubit',
      query: () => context.read<AppCqrs>().get(UserQuery(userId: 'success')),
      map: (user) => user,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple query page'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: QueryCubitBuilder<User, User>(
              queryCubit: userQueryCubit..get(),
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
            child: QueryCubitBuilder<User, User>(
              queryCubit: context.read<UserQueryCubit>()..get(),
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
