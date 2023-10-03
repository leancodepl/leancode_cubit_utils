import 'package:async/async.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

part 'paginated_cubit.g.dart';

/// A response containing a list of items and a flag indicating whether there is
/// a next page.
class PaginatedResponse<T> {
  /// Creates a new [PaginatedResponse] with the given [items] and [hasNextPage].
  PaginatedResponse({
    required this.items,
    required this.hasNextPage,
  });

  /// The list of items of type [T].
  final List<T> items;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;
}

/// Defines how to handle a new request when the previous one is still running.
enum PaginatedRequestMode {
  /// When a new request is triggered while the previous one is still running,
  /// the previous request is cancelled and the new one is executed.
  replace,

  /// When a new request is triggered while the previous one is still running,
  /// the new request is ignored.
  ignore,
}

// TODO: Add logging.
// TODO: Add error handling.

/// Base class for all paginated cubits.
abstract class PaginatedCubit<TPage extends PaginatedResponse<TItem>, TItem>
    extends Cubit<PaginatedState<TItem>> {
  /// Creates a new [PaginatedCubit] with the given [loggerTag] and [pageSize].
  PaginatedCubit({
    required String loggerTag,
    required int pageSize,
  })  : _logger = Logger(loggerTag),
        super(
          PaginatedState<TItem>(
            pageSize: pageSize,
            items: <TItem>[],
          ),
        );

  final Logger _logger;

  /// The request mode used by this cubit to handle duplicated requests.
  final PaginatedRequestMode requestMode = PaginatedRequestMode.ignore;
  CancelableOperation<TPage>? _operation;

  /// Gets the page.
  Future<void> fetchNextPage(int pageId, {bool refresh = false}) async {
    switch (requestMode) {
      case PaginatedRequestMode.replace:
        await _operation?.cancel();
      case PaginatedRequestMode.ignore:
        if (_operation?.isCompleted == false) {
          _logger.info('Previous operation is not completed. Ignoring.');
          return;
        }
    }
    if (refresh) {
      _logger.info('Refreshing...');
      emit(state.copyWith.type(PaginatedStateType.refresh));
    } else if (pageId == 0) {
      _logger.info('Loading first page...');
      emit(state.copyWith.type(PaginatedStateType.firstPageLoading));
    } else {
      _logger.info('Loading next page. PageId: $pageId');
      emit(state.copyWith.type(PaginatedStateType.nextPageLoading));
    }
    try {
      _operation = CancelableOperation.fromFuture(
        requestPage(pageId),
        onCancel: () => _logger.info('Canceling previous operation.'),
      );
      final page = await _operation?.value;
      if (page == null) {
        return;
      }
      final items = onData(page);
      emit(
        state.copyWith(
          type: PaginatedStateType.success,
          items: items,
          pageId: pageId,
          hasNextPage: page.hasNextPage,
        ),
      );
    } catch (e, s) {
      _logger.severe('Error loading page.', e, s);
      emit(
        state.copyWith(
          type: pageId == 0
              ? PaginatedStateType.firstPageError
              : PaginatedStateType.nextPageError,
        ),
      );
    }
  }

  /// Method getting the page from the server.
  Future<TPage> requestPage(int pageId);

  /// Method mapping the page to a list of items.
  List<TItem> onData(TPage page);

  /// Gets the initial page.
  void run() => fetchNextPage(0);

  /// Refreshes the list.
  void refresh() => fetchNextPage(0, refresh: true);
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
}

/// Represents the state of a [PaginatedCubit].
@CopyWith()
class PaginatedState<TItem> with EquatableMixin {
  /// Creates a new [PaginatedState] with the given [type], [items], [pageSize],
  /// [pageId] and [hasNextPage].
  const PaginatedState({
    this.type = PaginatedStateType.initial,
    required this.items,
    required this.pageSize,
    this.pageId = 0,
    this.hasNextPage = false,
  });

  /// The type of the state.
  final PaginatedStateType type;

  /// The list of items.
  final List<TItem> items;

  /// The number of items per page.
  final int pageSize;

  /// The id of the current page.
  final int pageId;

  /// A flag indicating whether there is a next page.
  final bool hasNextPage;

  @override
  List<Object?> get props => [
        type,
        items,
        pageSize,
        pageId,
        hasNextPage,
      ];
}
