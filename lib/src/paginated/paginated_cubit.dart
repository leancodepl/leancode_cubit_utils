import 'dart:async';

import 'package:async/async.dart';
import 'package:cqrs/cqrs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_args.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_state.dart';
import 'package:logging/logging.dart';

export 'package:leancode_cubit_utils/src/paginated/paginated_state.dart';

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
  Future<QueryResult<TRes>> execute();

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
abstract class PaginatedCubit<TPreRequestRes, TData, TRes, TItem>
    extends Cubit<PaginatedState<TData, TItem>> {
  /// Creates a new [PaginatedCubit] with the given [loggerTag] and [pageSize].
  PaginatedCubit({
    required String loggerTag,
    required int pageSize,
    PreRequest<TPreRequestRes, TData, TItem>? preRequest,
    this.preRequestMode = PreRequestMode.once,
    Duration searchDebounce = const Duration(milliseconds: 500),
  })  : _logger = Logger(loggerTag),
        _preRequest = preRequest,
        _searchDebounce = searchDebounce,
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
  final Duration _searchDebounce;
  bool _wasPreRequestRun = false;

  CancelableOperation<QueryResult<TPreRequestRes>>? _preRequestOperation;
  CancelableOperation<QueryResult<TRes>>? _requestOperation;
  CancelableOperation<void>? _searchQueryOperation;

  /// Gets the page.
  Future<void> fetchNextPage(int pageId, {bool refresh = false}) async {
    try {
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
            error: const PaginatedStateNoneError(),
          ),
        );
      } else if (result case QueryFailure(:final error)) {
        _logger.severe('Error loading page, error: $error');
        emit(
          await onQueryError(
            state.copyWithError(isFirstPage: pageId == 0),
            PaginatedStateQueryError(error),
          ),
        );
      }
    } catch (e, s) {
      _logger.severe('Error loading page, error: $e, stacktrace: $s');
      try {
        emit(
          await onQueryError(
            state.copyWithError(isFirstPage: pageId == 0),
            PaginatedStateException(e, s),
          ),
        );
      } catch (e, s) {
        _logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(
          state.copyWithError(
            isFirstPage: pageId == 0,
            error: PaginatedStateException(e, s),
          ),
        );
      }
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
      Future.delayed(_searchDebounce),
    );
    _searchQueryOperation?.value.whenComplete(() => fetchNextPage(0));
  }

  Future<void> _runPreRequest() async {
    try {
      await _preRequestOperation?.cancel();
      _logger.info('Running pre-request.');
      _preRequestOperation = CancelableOperation.fromFuture(
        _preRequest!.execute(),
        onCancel: () => _logger.info('Canceling previous pre-request.'),
      );
      final preRequestResponse =
          await _preRequestOperation?.valueOrCancellation();
      if (preRequestResponse == null) {
        return;
      }
      if (preRequestResponse case QuerySuccess(:final data)) {
        _logger.info('Pre-request completed.');
        _wasPreRequestRun = true;

        final mappedPreRequest = _preRequest?.map(data, state.data, state);
        emit(state.copyWith(data: mappedPreRequest));
      } else if (preRequestResponse case QueryFailure(:final error)) {
        _logger.severe('Error running pre-request, error: $error');
        emit(
          await onQueryError(
            state.copyWith(type: PaginatedStateType.firstPageError),
            PaginatedStateQueryError(error),
          ),
        );
      }
    } catch (e, s) {
      _logger.severe('Error running pre-request, error: $e, stacktrace: $s');
      try {
        emit(
          await onQueryError(
            state.copyWithError(isFirstPage: true),
            PaginatedStateException(e, s),
          ),
        );
      } catch (e, s) {
        _logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(
          state.copyWithError(
            isFirstPage: true,
            error: PaginatedStateException(e, s),
          ),
        );
      }
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

  /// Allows to handle errors in a custom way.
  Future<PaginatedState<TData, TItem>> onQueryError(
    PaginatedState<TData, TItem> state,
    PaginatedStateError error,
  ) async {
    return state.copyWith(error: error);
  }
}
