import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';

class TestQuery with EquatableMixin implements Query<String> {
  TestQuery({required this.id});

  final String id;

  @override
  String getFullName() => 'Test';

  @override
  String resultFactory(dynamic json) => json as String;

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [id];
}
