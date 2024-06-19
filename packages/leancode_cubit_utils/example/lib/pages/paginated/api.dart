import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:faker/faker.dart';

typedef Json = Map<String, dynamic>;

/// This is a fake API class as an example of paginated response from an API.
class Page {
  final bool hasNextPage;
  final List<User> users;

  Page({required this.hasNextPage, required this.users});

  factory Page.fromJson(Json json) {
    return Page(
      hasNextPage: json['hasNextPage'],
      users: [
        for (final user in json['users']) User.fromJson(user),
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
    return User(name: json['name'], jobTitle: json['jobTitle']);
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

  final String name;

  factory Filter.fromJson(Json json) {
    return Filter(name: json['name']);
  }

  Json toJson() {
    return {
      'name': name,
    };
  }
}

class Filters with EquatableMixin {
  Filters({
    this.availableFilters = const [],
    this.selectedFilters = const {},
  });

  final List<Filter> availableFilters;
  final Set<Filter> selectedFilters;

  factory Filters.fromJson(Json json) {
    return Filters(
      availableFilters: [
        for (final x in json['availableFilters']) Filter.fromJson(x),
      ],
      selectedFilters: {
        for (final x in json['selectedFilters']) Filter.fromJson(x),
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
      200,
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
      return http.Response('', 400);
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
      200,
    );
  }

  List<User> _filterUsers(List<User> users, List<Filter> filters) {
    return users
        .where((user) => filters.any((filter) => user.jobTitle == filter.name))
        .toList();
  }
}
