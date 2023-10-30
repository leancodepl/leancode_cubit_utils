import 'package:equatable/equatable.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_args.dart';

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

  /// The first page failed to load.
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
    this.items = const [],
    this.hasNextPage = false,
    this.error,
    required this.args,
    TData? data,
  })  : assert(
          null is TData || data != null,
          'You need to set TData to void or nullable type. If you want to use non-nullable type, you need to provide initial data.',
        ),
        data = data ?? (null as TData);

  /// The type of the state.
  final PaginatedStateType type;

  /// The list of items.
  final List<TItem> items;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;

  /// The error.
  final Object? error;

  /// Arguments of the request.
  final PaginatedArgs args;

  /// Additional data.
  final TData data;

  /// A flag indicating whether the state has an error.
  bool get hasError => error != null;

  /// A flag indicating whether the current page is the first page.
  bool get isFirstPage => args.isFirstPage;

  @override
  List<Object?> get props => [
        type,
        items,
        hasNextPage,
        error,
        args,
        data,
      ];

  /// Copies the [PaginatedState] with the given error.
  PaginatedState<TData, TItem> copyWithError([Object? error]) {
    return copyWith(
      type: isFirstPage
          ? PaginatedStateType.firstPageError
          : PaginatedStateType.nextPageError,
      error: error,
    );
  }

  /// Copies the [PaginatedState] with the given parameters.
  PaginatedState<TData, TItem> copyWith({
    PaginatedStateType? type,
    List<TItem>? items,
    bool? hasNextPage,
    PaginatedArgs? args,
    TData? data,
    Object? error,
    bool nullError = false,
  }) {
    return PaginatedState<TData, TItem>(
      type: type ?? this.type,
      items: items ?? this.items,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      args: args ?? this.args,
      data: data ?? this.data,
      error: nullError ? null : error ?? this.error,
    );
  }
}
