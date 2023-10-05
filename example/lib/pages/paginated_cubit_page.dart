import 'package:equatable/equatable.dart';
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
            decoration: const InputDecoration(
              hintText: 'Search',
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<SimplePaginatedCubit>().refresh,
              child: PaginatedCubitLayout(
                cubit: context.read<SimplePaginatedCubit>(),
                itemBuilder: (context, filters, index, items) => UserTile(
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
    void toggleFilter(Filter filter) {
      context.read<SimplePaginatedCubit>().onFilterPressed(filter);
    }

    return PaginatedCubitBuilder(
      cubit: context.read<SimplePaginatedCubit>(),
      builder: (context, state) {
        final availableFilters = state.data?.availableFilters;
        final selectedFilters = state.data?.selectedFilters ?? [];
        if (availableFilters == null) {
          return const SizedBox();
        } else {
          return Row(
            children: [
              const Text('Filters: '),
              ...availableFilters
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: FilterChip(
                        label: Text(filter.name),
                        selected: selectedFilters.contains(filter),
                        onSelected: (_) => toggleFilter(filter),
                      ),
                    ),
                  )
                  .toList(),
            ],
          );
        }
      },
    );
  }
}

class MockedApi {
  final _faker = Faker();

  late final jobTitles = List.generate(
    3,
    (index) => Filter(name: _faker.job.title().split(' ').last),
  );

  late final users = List.generate(
    120,
    (index) => User.fake(
      _faker,
      jobTitles.elementAt(index % jobTitles.length).name,
    ),
  );

  Future<Filters> getFilters() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return Filters(
      availableFilters: jobTitles,
      selectedFilters: [],
    );
  }

  Future<PaginatedResponse<Filters, User>> getUsers(
    int pageId,
    int pageSize, {
    List<Filter> selectedFilters = const [],
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    var filteredUsers = users;
    if (selectedFilters.isNotEmpty) {
      filteredUsers = _filterUsers(users, selectedFilters);
    }
    final usersPage =
        filteredUsers.skip(pageId * pageSize).take(pageSize).toList();
    return PaginatedResponse(
      items: usersPage,
      hasNextPage: pageId < 5,
    );
  }

  Future<PaginatedResponse<Filters, User>> searchUsers(
    int pageId,
    int pageSize,
    String searchQuery, {
    List<Filter> selectedFilters = const [],
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (searchQuery == 'error') {
      throw Exception();
    }
    var filteredUsers = users;
    if (selectedFilters.isNotEmpty) {
      filteredUsers = _filterUsers(users, selectedFilters);
    }
    final filteredUsersPage = filteredUsers
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

  List<User> _filterUsers(List<User> users, List<Filter> filters) {
    return users
        .where((user) => filters.any((filter) => user.jobTitle == filter.name))
        .toList();
  }
}

class User {
  User({
    required this.name,
    required this.email,
    required this.jobTitle,
  });

  factory User.fake(Faker faker, String jobTitle) {
    return User(
      name: faker.person.name(),
      email: faker.internet.email(),
      jobTitle: jobTitle,
    );
  }

  final String name;
  final String email;
  final String jobTitle;
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
      trailing: Text(user.jobTitle),
    );
  }
}

class Filter {
  Filter({required this.name});

  final String name;
}

class Filters with EquatableMixin {
  Filters({
    this.availableFilters = const [],
    this.selectedFilters = const [],
  });

  final List<Filter> availableFilters;
  final List<Filter> selectedFilters;

  @override
  List<Object?> get props => [
        availableFilters,
        selectedFilters,
      ];
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
      return api.getUsers(
        args.pageId,
        args.pageSize,
        selectedFilters: data?.selectedFilters ?? [],
      );
    } else {
      return api.searchUsers(
        args.pageId,
        args.pageSize,
        args.searchQuery,
        selectedFilters: data?.selectedFilters ?? [],
      );
    }
  }

  void onFilterPressed(Filter filter) {
    // TODO: Should be debounced.
    final filters = state.data;
    if (filters == null) {
      return;
    }
    if (filters.selectedFilters.contains(filter)) {
      filters.selectedFilters.remove(filter);
    } else {
      filters.selectedFilters.add(filter);
    }
    emit(state.copyWith(data: filters));
    fetchNextPage(0);
  }
}
