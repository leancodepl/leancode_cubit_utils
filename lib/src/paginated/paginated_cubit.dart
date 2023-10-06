import 'dart:async';

import 'package:async/async.dart';
import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_args.dart';
import 'package:logging/logging.dart';

/// Enum defining weather the pre-request should be run once or each time the
/// first page is loaded.
enum PreRequestMode {
  /// The pre-request should be run once before the first page is loaded.
  once,

  /// The pre-request should be run each time the first page is loaded.
  each,
}

/// Base class for all pre-request use cases.
abstract class PreRequest<TRes, TData, TItem> {
  /// Executes the use case.
  Future<TRes> execute();

  /// Map newly loaded data.
  TData map(TRes res, TData? data, PaginatedState<TData, TItem> state);
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

  /// Additional data.
  final TData? data;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;
}

/// Base class for all paginated cubits.
abstract class PaginatedCubit<TData, TPreRequestRes, TRes, TItem>
    extends Cubit<PaginatedState<TData, TItem>> {
  /// Creates a new [PaginatedCubit] with the given [loggerTag] and [pageSize].
  PaginatedCubit({
    required String loggerTag,
    required int pageSize,
    PreRequest<TPreRequestRes, TData, TItem>? preRequest,
    this.preRequestMode = PreRequestMode.once,
  })  : _logger = Logger(loggerTag),
        _preRequest = preRequest,
        super(
          PaginatedState<TData, TItem>(
            items: <TItem>[],
            args: PaginatedArgs(pageSize: pageSize),
          ),
        );

  /// The pre-request mode.
  final PreRequestMode preRequestMode;

  final Logger _logger;
  final PreRequest<TPreRequestRes, TData, TItem>? _preRequest;
  bool _wasPreRequestRun = false;

  CancelableOperation<TPreRequestRes>? _preRequestOperation;
  CancelableOperation<QueryResult<TRes>>? _requestOperation;
  CancelableOperation<void>? _searchQueryOperation;

  /// Gets the page.
  Future<void> fetchNextPage(int pageId, {bool refresh = false}) async {
    await _requestOperation?.cancel();

    if (refresh) {
      _logger.info('Refreshing...');
      emit(
        state.copyWith(
          type: PaginatedStateType.refresh,
          args: state.args.copyWith(pageId: 0),
        ),
      );
    } else if (pageId == 0) {
      _logger.info('Loading first page...');
      emit(
        state.copyWith(
          type: PaginatedStateType.firstPageLoading,
          args: state.args.copyWith(pageId: 0),
          items: <TItem>[],
        ),
      );
    } else {
      _logger.info('Loading next page. PageId: $pageId');
      emit(
        state.copyWith(
          type: PaginatedStateType.nextPageLoading,
          args: state.args.copyWith(pageId: pageId),
        ),
      );
    }

    if (_shouldRunPreRequest) {
      await _runPreRequest();
    }

    if (state.args.searchQuery.isNotEmpty) {
      _logger.info('Searching for ${state.args.searchQuery}');
    }
    _requestOperation = CancelableOperation.fromFuture(
      requestPage(state.args, state.data),
      onCancel: () => _logger.info('Canceling previous request.'),
    );
    final result = await _requestOperation?.valueOrCancellation();
    if (result == null) {
      return;
    }
    if (result case QuerySuccess(:final data)) {
      final page = onPageResult(data, state.args.pageId, state.data);
      _logger.info(
        'Page loaded. pageId: $pageId. hasNextPage: ${page.hasNextPage}. Number of items: ${page.items.length}',
      );
      emit(
        state.copyWith(
          type: PaginatedStateType.success,
          items: page.items,
          hasNextPage: page.hasNextPage,
          data: page.data,
        ),
      );
    } else if (result case QueryFailure(:final error)) {
      _logger.severe('Error loading page, error: $error');
      emit(
        state.copyWith(
          type: pageId == 0
              ? PaginatedStateType.firstPageError
              : PaginatedStateType.nextPageError,
          error: error,
        ),
      );
    }
  }

  bool get _shouldRunPreRequest =>
      _preRequest != null &&
      (!_wasPreRequestRun || preRequestMode == PreRequestMode.each) &&
      state.args.pageId == 0;

  /// Fetches the first page.
  Future<void> run() => fetchNextPage(0);

  /// Updates the search query.
  void updateSearchQuery(String searchQuery) {
    _searchQueryOperation?.cancel();

    emit(state.copyWith(args: state.args.copyWith(searchQuery: searchQuery)));

    _searchQueryOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(milliseconds: 500)),
    );
    _searchQueryOperation?.value.whenComplete(() => fetchNextPage(0));
  }

  Future<void> _runPreRequest() async {
    await _preRequestOperation?.cancel();
    _logger.info('Running pre-request.');
    try {
      _preRequestOperation = CancelableOperation.fromFuture(
        _preRequest!.execute(),
        onCancel: () => _logger.info('Canceling previous pre-request.'),
      );
      final preRequestResponse =
          await _preRequestOperation?.valueOrCancellation();
      if (preRequestResponse == null) {
        return;
      }
      final mappedPreRequest = _preRequest?.map(
        preRequestResponse,
        state.data,
        state,
      );

      _logger.info('Pre-request completed.');
      _wasPreRequestRun = true;

      emit(state.copyWith(data: mappedPreRequest));
    } catch (e, s) {
      _logger.severe('Error running pre-request, error: $e, stacktrace: $s');
      emit(state.copyWith(type: PaginatedStateType.firstPageError));
    }
  }

  /// Method getting the page from the server.
  Future<QueryResult<TRes>> requestPage(PaginatedArgs args, TData? data);

  /// Method mapping the page to a list of items.
  PaginatedResponse<TData, TItem> onPageResult(
    TRes page,
    int pageId,
    TData? data,
  );

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
class PaginatedState<TData, TItem> with EquatableMixin {
  /// Creates a new [PaginatedState].
  PaginatedState({
    this.type = PaginatedStateType.initial,
    required this.items,
    this.hasNextPage = false,
    this.error,
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
  final QueryError? error;

  /// Arguments of the request.
  final PaginatedArgs args;

  /// Additional data.
  final TData? data;

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
    QueryError? error,
    TData? data,
    bool setErrorToNull = false,
  }) {
    return PaginatedState<TData, TItem>(
      type: type ?? this.type,
      items: items ?? this.items,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      args: args ?? this.args,
      data: data ?? this.data,
      error: setErrorToNull ? null : error ?? this.error,
    );
  }
}
