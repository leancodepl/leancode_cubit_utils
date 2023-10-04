import 'dart:async';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

//part 'paginated_cubit.g.dart';

/// Base class for all pre-request use cases.
abstract class PreRequest<TData> {
  /// Executes the use case.
  Future<TData> execute();

  /// Method mapping the data.
  TData onData(TData data);
}

/// A response containing a list of items and a flag indicating whether there is
/// a next page.
class PaginatedResponse<TData, TItem> {
  /// Creates a new [PaginatedResponse] with the given [items] and [hasNextPage].
  PaginatedResponse({
    required this.items,
    this.data,
    required this.hasNextPage,
  });

  /// The list of items of type [TItem].
  final List<TItem> items;

  final TData? data;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;
}

///
class Args with EquatableMixin {
  ///
  const Args({
    this.pageId = 0,
    required this.pageSize,
    this.searchQuery = '',
    this.isRefresh = false,
  });

  ///
  final int pageId;

  ///
  final int pageSize;

  ///
  final String searchQuery;

  ///
  final bool isRefresh;

  /// Copies the [Args] with the given parameters.
  Args copyWith({
    int? pageId,
    int? pageSize,
    String? searchQuery,
    bool? isRefresh,
  }) {
    return Args(
      pageId: pageId ?? this.pageId,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefresh: isRefresh ?? this.isRefresh,
    );
  }

  @override
  List<Object?> get props => [
        pageId,
        pageSize,
        searchQuery,
        isRefresh,
      ];
}

/// Base class for all paginated cubits.
abstract class PaginatedCubit<TData, TItem>
    extends Cubit<PaginatedState<TItem>> {
  /// Creates a new [PaginatedCubit] with the given [loggerTag] and [pageSize].
  PaginatedCubit({
    required String loggerTag,
    required int pageSize,
  })  : _logger = Logger(loggerTag),
        super(
          PaginatedState<TItem>(
            items: <TItem>[],
            args: Args(pageSize: pageSize),
          ),
        );

  final Logger _logger;

  CancelableOperation<PaginatedResponse<TData, TItem>>? _requestOperation;
  CancelableOperation<void>? _searchQueryOperation;

  /// Gets the page.
  Future<void> fetchNextPage(int pageId, {bool refresh = false}) async {
    await _requestOperation?.cancel();

    if (refresh) {
      _logger.info('Refreshing...');
      emit(state.copyWith(type: PaginatedStateType.refresh));
    } else if (pageId == 0) {
      _logger.info('Loading first page...');
      emit(
        state.copyWith(
          type: PaginatedStateType.firstPageLoading,
          items: <TItem>[],
        ),
      );
    } else {
      _logger.info('Loading next page. PageId: $pageId');
      emit(state.copyWith(type: PaginatedStateType.nextPageLoading));
    }

    try {
      if (state.args.searchQuery.isNotEmpty) {
        _logger.info('Searching for ${state.args.searchQuery}');
      }
      _requestOperation = CancelableOperation.fromFuture(
        requestPage(state.args),
        onCancel: () => _logger.info('Canceling previous request.'),
      );
      final page = await _requestOperation?.valueOrCancellation();
      if (page == null) {
        return;
      }
      _logger.info(
        'Page loaded. pageId: $pageId. hasNextPage: ${page.hasNextPage}. Number of items: ${page.items.length}',
      );

      final items = onPageResult(page);
      emit(
        state.copyWith(
          type: PaginatedStateType.success,
          items: items,
          hasNextPage: page.hasNextPage,
          args: state.args.copyWith(pageId: pageId),
          setErrorToNull: true,
        ),
      );
    } catch (e, s) {
      _logger.severe('Error loading page, error: $e, stacktrace: $s');
      emit(
        state.copyWith(
          type: pageId == 0
              ? PaginatedStateType.firstPageError
              : PaginatedStateType.nextPageError,
          error: e,
        ),
      );
    }
  }

  /// Updates the search query.
  void updateSearchQuery(String searchQuery) {
    _searchQueryOperation?.cancel();

    emit(state.updateSearchQuery(searchQuery));

    _searchQueryOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(milliseconds: 500)),
    );
    _searchQueryOperation?.value.whenComplete(() => fetchNextPage(0));
  }

  /// Method getting the page from the server.
  Future<PaginatedResponse<TData, TItem>> requestPage(Args args);

  /// Method mapping the page to a list of items.
  List<TItem> onPageResult(PaginatedResponse<TData, TItem> page);

  /// Gets the initial page.
  void run() => fetchNextPage(0);

  /// Refreshes the list.
  Future<void> refresh() => fetchNextPage(0, refresh: true);
}

/// Type of the state of a [PaginatedCubit].
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

/// Represents the state of a [PaginatedCubit].
class PaginatedState<TItem> with EquatableMixin {
  /// Creates a new [PaginatedState].
  PaginatedState({
    this.type = PaginatedStateType.initial,
    required this.items,
    this.hasNextPage = false,
    this.error,
    required this.args,
  });

  /// The type of the state.
  final PaginatedStateType type;

  /// The list of items.
  final List<TItem> items;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;

  /// The error.
  final Object? error;

  /// Arguments of the request.
  final Args args;

  @override
  List<Object?> get props => [
        type,
        items,
        hasNextPage,
        error,
        args,
      ];

  /// Copies the [PaginatedState] with the given parameters.
  PaginatedState<TItem> copyWith({
    PaginatedStateType? type,
    List<TItem>? items,
    bool? hasNextPage,
    Args? args,
    Object? error,
    bool setErrorToNull = false,
  }) {
    return PaginatedState<TItem>(
      type: type ?? this.type,
      items: items ?? this.items,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: setErrorToNull ? null : error ?? this.error,
      args: args ?? this.args,
    );
  }

  /// Updates search query in state.
  PaginatedState<TItem> updateSearchQuery(String searchQuery) {
    final updatedArgs = args.copyWith(searchQuery: searchQuery);
    return copyWith(args: updatedArgs);
  }
}
