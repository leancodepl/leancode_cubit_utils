import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils/src/paginated/request_result.dart';
import 'package:logging/logging.dart';

export 'package:leancode_cubit_utils/src/paginated/paginated_state.dart';

/// A response containing a list of items and a flag indicating whether there is
/// a next page.
class PaginatedResponse<TData, TItem> {
  /// Creates a PaginatedResponse which gave full control over the items list to
  /// the caller. Useful in cases where you don't want to append the items to
  /// the existing list.
  PaginatedResponse.custom({
    required this.items,
    this.data,
    required this.hasNextPage,
  }) : _isAppend = false;

  /// Creates a PaginatedResponse which follows the strategy where next page
  /// items are appended to the existing list of items.
  /// In case of the first page (initial run, refresh), the page items replaces
  /// the existing items list.
  PaginatedResponse.append({
    required this.items,
    this.data,
    required this.hasNextPage,
  }) : _isAppend = true;

  final bool _isAppend;

  /// The list of items of type [TItem].
  final List<TItem> items;

  /// Additional data which can be modified when processing page in [PaginatedCubit.onPageResult].
  /// If the data is null, previous data is preserved. If the data is not null,
  /// the previous data is replaced in the state.
  final TData? data;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;
}

/// Base class for all paginated cubits.
abstract class PaginatedCubit<TData, TRes, TResData, TItem>
    extends Cubit<PaginatedState<TData, TItem>> {
  /// Creates a new [PaginatedCubit] with the given [loggerTag], [preRequest]
  /// and [config].
  PaginatedCubit({
    required String loggerTag,
    PreRequest<dynamic, dynamic, TData, TItem>? preRequest,
    PaginatedConfig? config,
  })  : logger = Logger(loggerTag),
        _preRequest = preRequest,
        _config = config ?? PaginatedConfigProvider.config,
        super(
          PaginatedState<TData, TItem>(
            items: <TItem>[],
            args: PaginatedArgs.fromConfig(
              config ?? PaginatedConfigProvider.config,
            ),
          ),
        );

  /// The logger.
  final Logger logger;

  final PaginatedConfig _config;
  final PreRequest<dynamic, dynamic, TData, TItem>? _preRequest;
  bool _wasPreRequestRun = false;

  CancelableOperation<dynamic>? _cancelableOperation;

  /// Gets the page.
  Future<void> fetchNextPage(
    int pageNumber, {
    bool refresh = false,
    bool withDebounce = false,
  }) async {
    if (withDebounce) {
      final result = await _runCancelableOperation<bool>(
        Future.delayed(_config.runDebounce, () => true),
      );
      if (result == null) {
        return;
      }
    }

    try {
      if (refresh) {
        logger.info('Refreshing...');
        emit(
          state.copyWith(
            type: PaginatedStateType.refresh,
            args: state.args.copyWith(pageNumber: _config.firstPageIndex),
          ),
        );
      } else if (pageNumber == _config.firstPageIndex) {
        logger.info('Loading first page...');
        emit(
          state.copyWith(
            type: PaginatedStateType.firstPageLoading,
            args: state.args.copyWith(pageNumber: _config.firstPageIndex),
            items: <TItem>[],
          ),
        );
      } else {
        logger.info('Loading next page. PageId: $pageNumber');
        emit(
          state.copyWith(
            type: PaginatedStateType.nextPageLoading,
            args: state.args.copyWith(pageNumber: pageNumber),
          ),
        );
      }

      if (_shouldRunPreRequest) {
        final preRequestSucceeded = await _runPreRequest();
        if (preRequestSucceeded) {
          _wasPreRequestRun = true;
        } else {
          return;
        }
      }

      if (state.args.searchQuery.isNotEmpty) {
        logger.info('Searching for ${state.args.searchQuery}');
      }
      final result = await _runCancelableOperation<TRes>(
        requestPage(state.args),
        onCancel: () => logger.info('Canceling previous request.'),
      );
      if (result == null) {
        return;
      }

      final resData = handleResponse(result);

      if (resData case Success(:final data)) {
        final page = onPageResult(data);
        logger.info(
          'Page loaded. pageNumber: $pageNumber. hasNextPage: ${page.hasNextPage}. Page size: ${page.items.length}',
        );
        emit(
          state.copyWith(
            type: PaginatedStateType.success,
            items: state.isFirstPage || !page._isAppend
                ? page.items
                : [...state.items, ...page.items],
            hasNextPage: page.hasNextPage,
            data: page.data,
            nullError: true,
          ),
        );
      } else if (resData case Failure(:final error)) {
        emit(await handleError(state.copyWithError(error)));
      }
    } catch (e, s) {
      logger.severe('Error loading page, error: $e, stacktrace: $s');
      try {
        emit(await handleError(state.copyWithError(e)));
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(state.copyWithError(e));
      }
    }
  }

  bool get _shouldRunPreRequest =>
      _preRequest != null &&
      (!_wasPreRequestRun || _config.preRequestMode == PreRequestMode.each) &&
      state.args.pageNumber == _config.firstPageIndex;

  /// Fetches the first page.
  Future<void> run() => fetchNextPage(_config.firstPageIndex);

  /// Updates the search query . If the query length is equal to or longer than
  /// [PaginatedConfig.searchBeginAt], the search will be run.
  /// Otherwise, first page will be loaded without the search query, but only if
  /// the previous search query was longer than of equal to [PaginatedConfig.searchBeginAt].
  Future<void> updateSearchQuery(String searchQuery) async {
    final previousSearchQuery = state.args.searchQuery;
    emit(state.copyWith(args: state.args.copyWith(searchQuery: searchQuery)));

    if (searchQuery.length < _config.searchBeginAt) {
      if (previousSearchQuery.length >= _config.searchBeginAt) {
        return _runSearch();
      }
      return;
    }

    return _runSearch();
  }

  /// Runs the search after the debounce.
  Future<void> _runSearch() async {
    final result = await _runCancelableOperation<bool>(
      Future.delayed(_config.searchDebounce, () => true),
    );
    if (result != null) {
      return fetchNextPage(_config.firstPageIndex);
    }
  }

  Future<bool> _runPreRequest() async {
    try {
      logger.info('Running pre-request.');
      final result = await _runCancelableOperation(
        _preRequest!.run(state),
        onCancel: () => logger.info('Canceling previous pre-request.'),
      );
      if (result == null) {
        return false;
      }
      emit(result);
      return !result.hasError;
    } catch (e, s) {
      logger.severe('Error running pre-request, error: $e, stacktrace: $s');
      rethrow;
    }
  }

  Future<T?> _runCancelableOperation<T>(
    Future<T> operation, {
    VoidCallback? onCancel,
  }) async {
    await _cancelableOperation?.cancel();
    _cancelableOperation = CancelableOperation<T>.fromFuture(
      operation,
      onCancel: onCancel,
    );
    final response = await _cancelableOperation?.valueOrCancellation();
    if (response case T()) {
      return response;
    }
    return null;
  }

  /// Method getting the page from the server.
  Future<TRes> requestPage(PaginatedArgs args);

  /// Method handling the response from the server.
  RequestResult<TResData> handleResponse(TRes res);

  /// Method mapping the page to a list of items.
  PaginatedResponse<TData, TItem> onPageResult(TResData page);

  /// Refreshes the list.
  Future<void> refresh() => fetchNextPage(0, refresh: true);

  /// Allows to handle errors in a custom way.
  Future<PaginatedState<TData, TItem>> handleError(
    PaginatedState<TData, TItem> state,
  ) async {
    return state;
  }
}
