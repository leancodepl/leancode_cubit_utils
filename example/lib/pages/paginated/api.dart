import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:faker/faker.dart';

/// This is a fake API class as an example of paginated response from an API.
class Page<T> {
  final bool hasNextPage;
  final List<T> items;

  Page({required this.hasNextPage, required this.items});
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

class Filter {
  Filter({required this.name});

  final String name;
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

  Future<QueryResult<Filters>> getFilters() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return QuerySuccess(
      Filters(
        availableFilters: jobTitles,
        selectedFilters: {},
      ),
    );
  }

  Future<QueryResult<Page<User>>> getUsers(
    int pageNumber,
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
        .skip(pageNumber * pageSize)
        .take(pageSize)
        .toList();
    return QuerySuccess(
      Page(
        items: usersPage,
        hasNextPage: usersPage.length >= pageSize,
      ),
    );
  }

  List<User> _filterUsers(List<User> users, List<Filter> filters) {
    return users
        .where((user) => filters.any((filter) => user.jobTitle == filter.name))
        .toList();
  }
}
