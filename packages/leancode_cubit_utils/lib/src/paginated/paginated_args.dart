import 'package:equatable/equatable.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_config.dart';

/// Arguments for a paginated cubit request.
class PaginatedArgs with EquatableMixin {
  ///
  const PaginatedArgs({
    required this.firstPageIndex,
    required this.pageNumber,
    required this.pageSize,
    required int searchBeginAt,
    String searchQuery = '',
    this.isRefresh = false,
  }) : _searchBeginAt = searchBeginAt,
       _searchQuery = searchQuery,
       super();

  /// Creates a new instance of [PaginatedArgs] from the given [config].
  factory PaginatedArgs.fromConfig(PaginatedConfig config) {
    return PaginatedArgs(
      firstPageIndex: config.firstPageIndex,
      pageSize: config.pageSize,
      pageNumber: config.firstPageIndex,
      searchBeginAt: config.searchBeginAt,
    );
  }

  /// The first page index.
  final int firstPageIndex;

  /// The page id.
  final int pageNumber;

  /// The page size.
  final int pageSize;

  final int _searchBeginAt;

  /// The search query.
  final String _searchQuery;

  /// Effective search query. Returns empty string if the search query is less
  /// than the searchBeginAt.
  String get searchQuery =>
      _searchQuery.length >= _searchBeginAt ? _searchQuery : '';

  /// A flag indicating whether the request is a refresh.
  final bool isRefresh;

  /// A flag indicating whether the current page is the first page.
  bool get isFirstPage => pageNumber == firstPageIndex;

  /// Copies the [PaginatedArgs] with the given parameters.
  PaginatedArgs copyWith({
    int? firstPageIndex,
    int? pageNumber,
    int? pageSize,
    String? searchQuery,
    bool? isRefresh,
  }) {
    return PaginatedArgs(
      firstPageIndex: firstPageIndex ?? this.firstPageIndex,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? _searchQuery,
      isRefresh: isRefresh ?? this.isRefresh,
      searchBeginAt: _searchBeginAt,
    );
  }

  @override
  List<Object?> get props => [
    firstPageIndex,
    pageNumber,
    pageSize,
    _searchQuery,
    _searchBeginAt,
    isRefresh,
  ];
}
