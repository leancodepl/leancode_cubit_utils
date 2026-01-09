import 'package:cqrs/cqrs.dart';
import 'package:example/cqrs/cqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';
import 'package:leancode_hooks/leancode_hooks.dart';

class UserQueryCubit extends QueryCubit<User, User> {
  UserQueryCubit({
    required this.cqrs,
    required this.userId,
  }) : super('UserRequestCubit');

  final Cqrs cqrs;
  final String userId;

  @override
  Future<QueryResult<User>> request() => cqrs.get(UserQuery(userId: userId));

  @override
  User map(User data) => data;
}

class QueryHookScreen extends StatelessWidget {
  const QueryHookScreen({super.key});

  @override
  Widget build(BuildContext context) => const QueryHookPage();
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
              cubit: userCubit,
              onSuccess: (context, data) =>
                  Text(data != null ? '${data.name} ${data.surname}' : '-'),
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

class QueryScreen extends StatelessWidget {
  const QueryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => UserQueryCubit(
          cqrs: context.read<Cqrs>(),
          userId: 'success',
        )..run(),
        child: const QueryPage(),
      );
}

class QueryPage extends StatelessWidget {
  const QueryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Simple request page')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: RequestCubitBuilder(
                cubit: context.read<UserQueryCubit>(),
                onSuccess: (context, data) =>
                    Text(data != null ? '${data.name} ${data.surname}' : '-'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: context.read<UserQueryCubit>().refresh,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
}
