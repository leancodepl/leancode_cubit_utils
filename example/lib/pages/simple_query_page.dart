import 'package:cqrs/cqrs.dart';
import 'package:example/cqrs/cqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class UserQueryCubit extends QueryCubit<User, User> {
  UserQueryCubit({
    required this.cqrs,
    required this.userId,
  });

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
        userId: 'error',
      ),
      child: const SimpleQueryPage(),
    );
  }
}

class SimpleQueryPage extends StatelessWidget {
  const SimpleQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple query page')),
      body: Center(
        child: QueryCubitBuilder<User, User>(
          queryCubit: context.read<UserQueryCubit>()..get(),
          builder: (context, data) => Text('${data.name} ${data.surname}'),
        ),
      ),
    );
  }
}
