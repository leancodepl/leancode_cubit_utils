import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:mocktail/mocktail.dart';

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

class UserQuery with EquatableMixin implements Query<User> {
  UserQuery({
    required this.userId,
  });

  final String userId;

  @override
  String getFullName() => 'User';

  @override
  User resultFactory(json) => User.fromJson(json);

  @override
  Json toJson() => {'userId': userId};

  @override
  List<Object?> get props => [userId];
}

class AppCqrs extends Mock implements Cqrs {
  AppCqrs();
}

AppCqrs createMockedCqrs() {
  final cqrs = AppCqrs();
  when(
    () => cqrs.get(UserQuery(userId: 'success')),
  ).thenAnswer(
    (invocation) => Future.delayed(
      const Duration(milliseconds: 600),
      () => const QuerySuccess(User('John', 'Doe')),
    ),
  );
  when(
    () => cqrs.get(UserQuery(userId: 'error')),
  ).thenAnswer(
    (invocation) => Future.delayed(
      const Duration(milliseconds: 600),
      () => const QueryFailure(QueryError.unknown),
    ),
  );

  return cqrs;
}
