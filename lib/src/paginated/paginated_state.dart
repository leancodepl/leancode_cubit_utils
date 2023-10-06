import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_args.dart';

sealed class PaginatedStateError {
  const PaginatedStateError();

  bool get hasError;
}

class PaginatedStateNoneError extends PaginatedStateError {
  const PaginatedStateNoneError();

  @override
  bool get hasError => false;
}

class PaginatedStateQueryError extends PaginatedStateError {
  const PaginatedStateQueryError(this.error);

  final QueryError error;

  @override
  bool get hasError => true;
}

class PaginatedStateException extends PaginatedStateError {
  const PaginatedStateException(this.exception, this.stackTrace);

  final Object exception;
  final StackTrace stackTrace;

  @override
  bool get hasError => true;
}

/// Type of the [PaginatedState].
enum PaginatedStateType {
  /// Initial state of the cubit. No request has been made yet.
  initial,

  /// The first page is loading.
  firstPageLoading,

  /// The next page is loading.
  nextPageLoading,

  /// Is refreshing the list.
  refresh,

  /// The next page failed to load.
  firstPageError,

  /// The next page failed to load.
  nextPageError,

  /// The list was loaded successfully.
  success;

  /// A flag indicating whether the state is loading.
  bool get shouldNotGetNextPage => [
        PaginatedStateType.firstPageLoading,
        PaginatedStateType.nextPageLoading,
        PaginatedStateType.refresh,
        PaginatedStateType.nextPageError,
      ].contains(this);
}

/// Represents the state of a PaginatedCubit.
class PaginatedState<TData, TItem> with EquatableMixin {
  /// Creates a new [PaginatedState].
  const PaginatedState({
    this.type = PaginatedStateType.initial,
    required this.items,
    this.hasNextPage = false,
    this.error = const PaginatedStateNoneError(),
    required this.args,
    this.data,
  });

  /// The type of the state.
  final PaginatedStateType type;

  /// The list of items.
  final List<TItem> items;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;

  /// The error.
  final PaginatedStateError error;

  /// Arguments of the request.
  final PaginatedArgs args;

  /// Additional data.
  final TData? data;

  /// A flag indicating whether the state has an error.
  bool get hasError => error.hasError;

  @override
  List<Object?> get props => [
        type,
        items,
        hasNextPage,
        error,
        args,
        data,
      ];

  /// Copies the [PaginatedState] with the given parameters.
  PaginatedState<TData, TItem> copyWith({
    PaginatedStateType? type,
    List<TItem>? items,
    bool? hasNextPage,
    PaginatedArgs? args,
    TData? data,
    PaginatedStateError? error,
  }) {
    return PaginatedState<TData, TItem>(
      type: type ?? this.type,
      items: items ?? this.items,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      args: args ?? this.args,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
