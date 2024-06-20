import 'dart:convert';

import 'package:example/http/status_codes.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:faker/faker.dart';

typedef Json = Map<String, dynamic>;

/// This is a fake API class as an example of paginated response from an API.
class Page {
  Page({required this.hasNextPage, required this.users});

  factory Page.fromJson(Json json) {
    return Page(
      hasNextPage: json['hasNextPage'] as bool,
      users: [
        for (final user in json['users'] as Iterable)
          User.fromJson(user as Json),
      ],
    );
  }

  Json toJson() {
    return {
      'hasNextPage': hasNextPage,
      'users': [
        for (final user in users) user.toJson(),
      ],
    };
  }

  final bool hasNextPage;
  final List<User> users;
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

  factory User.fromJson(Json json) {
    return User(
      name: json['name'] as String,
      jobTitle: json['jobTitle'] as String,
    );
  }

  Json toJson() {
    return {
      'name': name,
      'jobTitle': jobTitle,
    };
  }

  final String name;
  final String jobTitle;
}

class Filter {
  Filter({required this.name});

  factory Filter.fromJson(Json json) {
    return Filter(name: json['name'] as String);
  }

  Json toJson() {
    return {
      'name': name,
    };
  }

  final String name;
}

class Filters with EquatableMixin {
  Filters({
    this.availableFilters = const [],
    this.selectedFilters = const {},
  });

  factory Filters.fromJson(Json json) {
    return Filters(
      availableFilters: [
        for (final filter in json['availableFilters'] as Iterable)
          Filter.fromJson(filter as Json),
      ],
      selectedFilters: {
        for (final filter in json['selectedFilters'] as Iterable)
          Filter.fromJson(filter as Json),
      },
    );
  }

  Json toJson() {
    return {
      'availableFilters': [
        for (final filter in availableFilters) filter.toJson(),
      ],
      'selectedFilters': [
        for (final filter in selectedFilters) filter.toJson(),
      ],
    };
  }

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

  Future<http.Response> getFilters() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return http.Response(
      jsonEncode(
        Filters(
          availableFilters: jobTitles,
          selectedFilters: {},
        ),
      ),
      StatusCode.ok.value,
    );
  }

  Future<http.Response> getUsers(
    int pageNumber,
    int pageSize, {
    List<Filter> selectedFilters = const [],
    String searchQuery = '',
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (searchQuery == 'error') {
      return http.Response('', StatusCode.badRequest.value);
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
    return http.Response(
      jsonEncode(
        Page(
          users: usersPage,
          hasNextPage: usersPage.length >= pageSize,
        ),
      ),
      StatusCode.ok.value,
    );
  }

  List<User> _filterUsers(List<User> users, List<Filter> filters) {
    return users
        .where((user) => filters.any((filter) => user.jobTitle == filter.name))
        .toList();
  }
}
