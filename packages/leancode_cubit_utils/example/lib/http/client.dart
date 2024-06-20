import 'dart:convert';

import 'package:example/http/status_codes.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class User {
  final String name;
  final String surname;

  const User(this.name, this.surname);

  factory User.fromJson(Json json) {
    return User(json['name'] as String, json['surname'] as String);
  }

  Json toJson() {
    return {
      'name': name,
      'surname': surname,
    };
  }
}

class AppHttpClient extends Mock implements http.Client {}

AppHttpClient createMockedHttpClient() {
  final client = AppHttpClient();
  when(
    () => client.get(Uri.parse('success')),
  ).thenAnswer(
    (invocation) => Future.delayed(
      const Duration(milliseconds: 1000),
      () => http.Response(
        jsonEncode(const User('John', 'Doe')),
        StatusCode.ok.value,
      ),
    ),
  );
  when(
    () => client.get(Uri.parse('error')),
  ).thenAnswer(
    (invocation) => Future.delayed(
      const Duration(milliseconds: 1000),
      () => http.Response('', StatusCode.badRequest.value),
    ),
  );

  return client;
}
