import 'package:equatable/equatable.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_config.dart';

/// Arguments for a paginated cubit request.
class PaginatedArgs with EquatableMixin {
  ///
  const PaginatedArgs({
    required this.firstPageIndex,
    required this.pageNumber,
    required this.pageSize,
    this.searchQuery = '',
    this.isRefresh = false,
  });

  /// Creates a new instance of [PaginatedArgs] from the given [config].
  factory PaginatedArgs.fromConfig(PaginatedConfig config) {
    return PaginatedArgs(
      firstPageIndex: config.firstPageIndex,
      pageSize: config.pageSize,
      pageNumber: config.firstPageIndex,
    );
  }

  /// The first page index.
  final int firstPageIndex;

  /// The page id.
  final int pageNumber;

  /// The page size.
  final int pageSize;

  /// The search query.
  final String searchQuery;

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
      searchQuery: searchQuery ?? this.searchQuery,
      isRefresh: isRefresh ?? this.isRefresh,
    );
  }

  @override
  List<Object?> get props => [
        pageNumber,
        pageSize,
        searchQuery,
        isRefresh,
      ];
}
