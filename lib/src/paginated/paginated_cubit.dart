import 'dart:async';

import 'package:async/async.dart';
import 'package:cqrs/cqrs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_args.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_config.dart';
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
  Future<QueryResult<TRes>> request(PaginatedState<TData, TItem> state);

  /// Map newly loaded data.
  TData map(TRes res, PaginatedState<TData, TItem> state);
}

/// Type definition for the page response.
typedef PageResponse<TItem> = ({List<TItem> items, bool hasNextPage});

/// Base class for all paginated cubits.
abstract class PaginatedCubit<TPreRequestRes, TData, TRes, TItem>
    extends Cubit<PaginatedState<TData, TItem>> {
  /// Creates a new [PaginatedCubit] with the given [loggerTag], [preRequest]
  /// and [config].
  PaginatedCubit({
    required String loggerTag,
    PreRequest<TPreRequestRes, TData, TItem>? preRequest,
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
  final PreRequest<TPreRequestRes, TData, TItem>? _preRequest;
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
      final result = await _runCancelableOperation<QueryResult<TRes>>(
        requestPage(state.args),
        onCancel: () => logger.info('Canceling previous request.'),
      );
      if (result == null) {
        return;
      }

      if (result case QuerySuccess(:final data)) {
        final page = onPageResult(data);
        logger.info(
          'Page loaded. pageNumber: $pageNumber. hasNextPage: ${page.hasNextPage}. Number of items: ${page.items.length}',
        );
        emit(
          state.copyWith(
            type: PaginatedStateType.success,
            items: state.isFirstPage
                ? page.items
                : [...state.items, ...page.items],
            hasNextPage: page.hasNextPage,
            data: state.data,
            error: const PaginatedStateNoneError(),
          ),
        );
      } else if (result case QueryFailure(:final error)) {
        logger.severe('Error loading page, error: $error');
        emit(
          await onQueryError(
            state.copyWithError(),
            PaginatedStateQueryError(error),
          ),
        );
      }
    } catch (e, s) {
      logger.severe('Error loading page, error: $e, stacktrace: $s');
      try {
        emit(
          await onQueryError(
            state.copyWithError(),
            PaginatedStateException(e, s),
          ),
        );
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(
          state.copyWithError(
            error: PaginatedStateException(e, s),
          ),
        );
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
      final result = await _runCancelableOperation<QueryResult<TPreRequestRes>>(
        _preRequest!.request(state),
        onCancel: () => logger.info('Canceling previous pre-request.'),
      );
      if (result == null) {
        return false;
      }
      if (result case QuerySuccess(:final data)) {
        logger.info('Pre-request completed.');

        final mappedPreRequest = _preRequest?.map(data, state);
        emit(state.copyWith(data: mappedPreRequest));
        return true;
      } else if (result case QueryFailure(:final error)) {
        logger.severe('Error running pre-request, error: $error');
        emit(
          await onQueryError(
            state.copyWith(type: PaginatedStateType.firstPageError),
            PaginatedStateQueryError(error),
          ),
        );
        return false;
      } else {
        return false;
      }
    } catch (e, s) {
      logger.severe('Error running pre-request, error: $e, stacktrace: $s');
      try {
        emit(
          await onQueryError(
            state.copyWith(type: PaginatedStateType.firstPageError),
            PaginatedStateException(e, s),
          ),
        );
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        emit(
          state.copyWithError(
            error: PaginatedStateException(e, s),
          ),
        );
      }
      return false;
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
  Future<QueryResult<TRes>> requestPage(PaginatedArgs args);

  /// Method mapping the page to a list of items.
  /* PaginatedResponse<TData, TItem> */
  PageResponse<TItem> onPageResult(TRes page);

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
