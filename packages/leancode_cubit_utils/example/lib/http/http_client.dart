import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class User {
  final String name;
  final String surname;

  const User(this.name, this.surname);

  factory User.fromJson(Json json) {
    return User(json['name'], json['surname']);
  }

  Json toJson() {
    return {
      'name': name,
      'surname': surname,
    };
  }
}

class AppHttpClient extends Mock implements http.Client {
  AppHttpClient();
}

AppHttpClient createMockedHttpClient() {
  final client = AppHttpClient();
  when(
    () => client.get(Uri.parse('success')),
  ).thenAnswer(
    (invocation) => Future.delayed(
      const Duration(milliseconds: 1000),
      () => http.Response(jsonEncode(const User('John', 'Doe')), 200),
    ),
  );
  when(
    () => client.get(Uri.parse('error')),
  ).thenAnswer(
    (invocation) => Future.delayed(
      const Duration(milliseconds: 1000),
      () => http.Response('', 400),
    ),
  );

  return client;
}
