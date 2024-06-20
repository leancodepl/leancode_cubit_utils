import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'http_status_codes.dart';

typedef Json = Map<String, dynamic>;

/// This is a fake API class as an example of paginated response from an API.
class Page {
  Page({required this.hasNextPage, required this.cities});

  factory Page.fromJson(Json json) {
    return Page(
      hasNextPage: json['hasNextPage'] as bool,
      cities: [
        for (final city in json['cities'] as Iterable)
          City.fromJson(city as Json),
      ],
    );
  }

  final bool hasNextPage;
  final List<City> cities;

  Json toJson() {
    return {
      'hasNextPage': hasNextPage,
      'cities': [
        for (final city in cities) city.toJson(),
      ],
    };
  }
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

  factory City.fromJson(Json json) {
    return City(
      name: json['name'] as String,
      type: json['type'] as CityType,
    );
  }

  Json toJson() {
    return {
      'name': name,
      'type': type,
    };
  }

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
    return http.Response(jsonEncode(CityType.values), StatusCode.ok.value);
  }

  Future<http.Response> getCities(
    int pageNumber,
    int pageSize, {
    List<CityType> selectedFilters = const [],
    String searchQuery = '',
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (searchQuery == 'error') {
      return http.Response('', StatusCode.badRequest.value);
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
      jsonEncode(
        Page(
          cities: citiesPage,
          hasNextPage: citiesPage.length >= pageSize,
        ),
      ),
      StatusCode.ok.value,
    );
  }

  List<City> _filterCities(List<City> cities, List<CityType> types) {
    return cities
        .where((city) => types.any((type) => city.type == type))
        .toList();
  }
}
