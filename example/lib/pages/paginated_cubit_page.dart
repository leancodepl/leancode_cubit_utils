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
      body: Column(
        children: [
          const FiltersRow(),
          TextField(
            onChanged: context.read<SimplePaginatedCubit>().updateSearchQuery,
            decoration: const InputDecoration(hintText: 'Search'),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<SimplePaginatedCubit>().refresh,
              child: PaginatedCubitLayout(
                cubit: context.read<SimplePaginatedCubit>(),
                itemBuilder: (context, _, index, items) => UserTile(
                  user: items[index],
                ),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FiltersRow extends StatelessWidget {
  const FiltersRow({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = context.select<SimplePaginatedCubit, Filters?>(
      (cubit) => cubit.state.data,
    );
    return Row(
      children: [
        const Text('Filters: '),
        if (filters?.availableFilters.isNotEmpty == true)
          ...filters!.availableFilters
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FilterChip(
                    label: Text(filter.name),
                    selected: filters.selectedFilters.contains(filter),
                    onSelected: (_) {},
                  ),
                ),
              )
              .toList(),
      ],
    );
  }
}

class MockedApi {
  final _faker = Faker();

  late final filters = List.generate(
    3,
    (index) => Filter(name: _faker.job.title().split(' ').first),
  );

  late final users = List.generate(120, (index) => User.fake(_faker));

  Future<Filters> getFilters() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return Filters(
      availableFilters: filters,
      selectedFilters: [],
    );
  }

  Future<PaginatedResponse<Filters, User>> getUsers(
    int pageId,
    int pageSize,
  ) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    final usersPage = users.skip(pageId * pageSize).take(pageSize).toList();
    return PaginatedResponse(
      items: usersPage,
      hasNextPage: pageId < 5,
    );
  }

  Future<PaginatedResponse<Filters, User>> searchUsers(
    int pageId,
    int pageSize,
    String searchQuery,
  ) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (searchQuery == 'error') {
      throw Exception();
    }
    final filteredUsersPage = users
        .where(
          (user) => user.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .skip(pageId * pageSize)
        .take(pageSize)
        .toList();
    return PaginatedResponse(
      items: filteredUsersPage,
      hasNextPage: pageId < 5 && filteredUsersPage.length >= pageSize,
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

class Filter {
  Filter({required this.name});

  final String name;
}

class Filters {
  Filters({
    this.availableFilters = const [],
    this.selectedFilters = const [],
  });

  final List<Filter> availableFilters;
  final List<Filter> selectedFilters;
}

class FiltersPreRequest extends PreRequest<Filters> {
  FiltersPreRequest({required this.api});

  final MockedApi api;

  @override
  Future<Filters> execute() => api.getFilters();
}

class SimplePaginatedCubit extends PaginatedCubit<Filters, User, User> {
  SimplePaginatedCubit(this.api)
      : super(
          loggerTag: 'SimplePaginatedCubit',
          pageSize: 20,
          preRequest: FiltersPreRequest(api: api),
        );

  final MockedApi api;

  @override
  List<User> onPageResult(PaginatedResponse<Filters, User> page) {
    return [...state.items, ...page.items];
  }

  @override
  Future<PaginatedResponse<Filters, User>> requestPage(
    PaginatedArgs args,
    Filters? data,
  ) {
    if (args.searchQuery.isEmpty) {
      return api.getUsers(args.pageId, args.pageSize);
    } else {
      return api.searchUsers(args.pageId, args.pageSize, args.searchQuery);
    }
  }
}
