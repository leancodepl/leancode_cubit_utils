import 'package:async/async.dart';
import 'package:cqrs/cqrs.dart';
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
                itemBuilder: (context, additionalData, index, items) {
                  final user = items[index];
                  final selectedUsers = additionalData?.selectedUsers ?? {};
                  return UserTile(
                    user: user,
                    isSelected: selectedUsers.contains(user),
                  );
                },
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
        final selectedFilters = state.data?.selectedFilters ?? {};
        if (availableFilters == null) {
          return const CircularProgressIndicator();
        } else {
          return Wrap(
            spacing: 8,
            children: [
              ...availableFilters
                  .map(
                    (filter) => FilterChip(
                      label: Text(filter.name),
                      selected: selectedFilters.contains(filter),
                      onSelected: (_) => toggleFilter(filter),
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

class Page<T> {
  final bool hasNextPage;
  final List<T> items;

  Page({required this.hasNextPage, required this.items});
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
      selectedFilters: {},
    );
  }

  Future<QueryResult<Page<User>>> getUsers(
    int pageId,
    int pageSize, {
    List<Filter> selectedFilters = const [],
    String searchQuery = '',
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (searchQuery == 'error') {
      return const QueryFailure(QueryError.network);
    }
    var filteredUsers = users;
    if (selectedFilters.isNotEmpty) {
      filteredUsers = _filterUsers(users, selectedFilters);
    }
    final usersPage = filteredUsers
        .where(
          (user) => user.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .skip(pageId * pageSize)
        .take(pageSize)
        .toList();
    return QuerySuccess(
      Page(
        items: usersPage,
        hasNextPage: pageId < 5 && usersPage.length >= pageSize,
      ),
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
    required this.jobTitle,
  });

  factory User.fake(Faker faker, String jobTitle) {
    return User(
      name: faker.person.name(),
      jobTitle: jobTitle,
    );
  }

  final String name;
  final String jobTitle;
}

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.isSelected,
  });

  final User user;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(user.name),
      subtitle: Text(user.jobTitle),
      value: isSelected,
      onChanged: (_) => context.read<SimplePaginatedCubit>().onTilePressed(
            user,
          ),
    );
  }
}

class Filter {
  Filter({required this.name});

  final String name;
}

class AdditionalData with EquatableMixin {
  AdditionalData({
    this.availableFilters = const [],
    this.selectedFilters = const {},
    this.selectedUsers = const {},
  });

  final List<Filter> availableFilters;
  final Set<Filter> selectedFilters;
  final Set<User> selectedUsers;

  @override
  List<Object?> get props => [
        availableFilters,
        selectedFilters,
        selectedUsers,
      ];

  AdditionalData copyWith({
    List<Filter>? availableFilters,
    Set<Filter>? selectedFilters,
    Set<User>? selectedUsers,
  }) {
    return AdditionalData(
      availableFilters: availableFilters ?? this.availableFilters,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      selectedUsers: selectedUsers ?? this.selectedUsers,
    );
  }
}

class Filters with EquatableMixin {
  Filters({
    this.availableFilters = const [],
    this.selectedFilters = const {},
  });

  final List<Filter> availableFilters;
  final Set<Filter> selectedFilters;

  @override
  List<Object?> get props => [availableFilters, selectedFilters];
}

class FiltersPreRequest extends PreRequest<Filters, AdditionalData, User> {
  FiltersPreRequest({
    required this.api,
  });

  final MockedApi api;

  @override
  Future<Filters> execute() async {
    final filters = await api.getFilters();
    return Filters(
      availableFilters: filters.availableFilters,
      selectedFilters: filters.selectedFilters.toSet(),
    );
  }

  @override
  AdditionalData map(
    Filters res,
    AdditionalData? data,
    PaginatedState<AdditionalData, User> state,
  ) {
    return AdditionalData(
      availableFilters: res.availableFilters,
      selectedFilters: data?.selectedFilters
              .where((e) => res.availableFilters.contains(e))
              .toSet() ??
          {},
    );
  }
}

class SimplePaginatedCubit
    extends PaginatedCubit<Filters, AdditionalData, Page<User>, User> {
  SimplePaginatedCubit(this.api)
      : super(
          loggerTag: 'SimplePaginatedCubit',
          pageSize: 20,
          preRequest: FiltersPreRequest(api: api),
        );

  final MockedApi api;
  CancelableOperation<void>? _filtersDebounceOperation;

  @override
  Future<QueryResult<Page<User>>> requestPage(
    PaginatedArgs args,
    AdditionalData? data,
  ) {
    return api.getUsers(
      args.pageId,
      args.pageSize,
      selectedFilters: data?.selectedFilters.toList() ?? [],
      searchQuery: args.searchQuery,
    );
  }

  @override
  PaginatedResponse<AdditionalData, User> onPageResult(
    Page<User> page,
    int pageId,
    AdditionalData? data,
  ) {
    return PaginatedResponse(
      items: pageId == 0 ? page.items : [...state.items, ...page.items],
      hasNextPage: page.hasNextPage,
      data: data,
    );
  }

  Future<void> onFilterPressed(Filter filter) async {
    await _filtersDebounceOperation?.cancel();

    final selectedFilters = state.data?.selectedFilters;
    if (selectedFilters == null) {
      return;
    }

    emit(
      state.copyWith(
        data: state.data?.copyWith(
          selectedFilters: switch (selectedFilters.contains(filter)) {
            true => selectedFilters.difference({filter}),
            false => selectedFilters.union({filter}),
          },
        ),
      ),
    );

    _filtersDebounceOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(milliseconds: 300)),
    );
    _filtersDebounceOperation?.value.whenComplete(() => fetchNextPage(0));
  }

  void onTilePressed(User user) {
    final selectedUsers = state.data?.selectedUsers;
    if (selectedUsers == null) {
      return;
    }
    emit(
      state.copyWith(
        data: state.data?.copyWith(
          selectedUsers: switch (selectedUsers.contains(user)) {
            true => selectedUsers.difference({user}),
            false => selectedUsers.union({user}),
          },
        ),
      ),
    );
  }
}
