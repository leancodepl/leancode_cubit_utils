import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

typedef Json = Map<String, dynamic>;

/// This is a fake API class as an example of paginated response from an API.
class Page<T> {
  Page({required this.hasNextPage, required this.items});

  factory Page.fromJson(Json json) {
    return Page( 
      hasNextPage: json['hasNextPage'],
      items: [
        for (final user in json['items']) T.fromJson(user),
      ],
    );
  }

  final bool hasNextPage;
  final List<T> items;
}

enum CityType {
  small,
  medium,
  large,
}

class City with EquatableMixin {
  City({
    required this.name,
    required this.type,
  });

  final String name;
  final CityType type;

  @override
  List<Object?> get props => [name, type];
}

class MockedApi extends Mock implements ApiBase {}

class ApiBase {
  final random = Random();

  late final cities = List.generate(60, (index) {
    final cityName = 'City$index';
    final cityType = CityType.values[random.nextInt(CityType.values.length)];
    return City(name: cityName, type: cityType);
  });

  Future<http.Response> getTypes() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return http.Response(jsonEncode(CityType.values), 200);
  }

  Future<http.Response> getCities(
    int pageNumber,
    int pageSize, {
    List<CityType> selectedFilters = const [],
    String searchQuery = '',
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (searchQuery == 'error') {
      return http.Response('', 400);
    }
    var filteredUsers = cities;
    if (selectedFilters.isNotEmpty) {
      filteredUsers = _filterCities(cities, selectedFilters);
    }
    final citiesPage = filteredUsers
        .where(
          (city) => city.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .skip(pageNumber * pageSize)
        .take(pageSize)
        .toList();
    return http.Response(
      Page(
        items: citiesPage,
        hasNextPage: citiesPage.length >= pageSize,
      ),
    );
  }

  List<City> _filterCities(List<City> cities, List<CityType> types) {
    return cities
        .where((city) => types.any((type) => city.type == type))
        .toList();
  }
}
