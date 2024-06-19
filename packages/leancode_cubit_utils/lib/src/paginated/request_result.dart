import 'package:equatable/equatable.dart';

/// A class which represents a result which can be either a success or a failure.
sealed class RequestResult<T> with EquatableMixin {
  /// Creates a new [RequestResult].
  const RequestResult();
}

/// A class which represents a failure result.
class Failure<T> extends RequestResult<T> {
  /// Creates a new [Failure] with the given [error].
  const Failure(this.error);

  /// The error which caused the failure.
  final Object? error;

  @override
  List<Object?> get props => [error];
}

/// A class which represents a success result.
class Success<T> extends RequestResult<T> {
  /// Creates a new [Success] with the given [data].
  const Success(this.data);

  /// The data returned by the success result.
  final T data;

  @override
  List<Object?> get props => [data];
}
