import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class PaginatedCubitScreen extends StatelessWidget {
  const PaginatedCubitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimplePaginatedCubit(MockedApi())..run(),
      child: const PaginatedCubitPage(),
    );
  }
}

class PaginatedCubitPage extends StatelessWidget {
  const PaginatedCubitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PaginatedCubit Page'),
      ),
      body: PaginatedCubitLayout(
        cubit: context.read<SimplePaginatedCubit>(),
        itemBuilder: (context, index, items) => UserTile(user: items[index]),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}

class MockedApi {
  final _faker = Faker();

  Future<PaginatedResponse<User>> getUsers(int pageId, int pageSize) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return PaginatedResponse(
      items: List.generate(
        pageSize,
        (index) => User.fake(_faker),
      ).toList(),
      hasNextPage: pageId < 5,
    );
  }
}

class User {
  User({
    required this.name,
    required this.email,
  });

  factory User.fake(Faker faker) {
    return User(
      name: faker.person.name(),
      email: faker.internet.email(),
    );
  }

  final String name;

  final String email;
}

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(user.name),
      subtitle: Text(user.email),
    );
  }
}

class SimplePaginatedCubit
    extends PaginatedCubit<PaginatedResponse<User>, User> {
  SimplePaginatedCubit(this.api)
      : super(
          loggerTag: 'SimplePaginatedCubit',
          pageSize: 20,
        );

  final MockedApi api;

  @override
  List<User> onData(PaginatedResponse<User> page) {
    return state.items.followedBy(page.items).toList();
  }

  @override
  Future<PaginatedResponse<User>> requestPage(int pageId) {
    return api.getUsers(pageId, state.pageSize);
  }
}
