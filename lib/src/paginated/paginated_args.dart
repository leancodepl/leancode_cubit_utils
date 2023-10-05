import 'package:equatable/equatable.dart';

/// Arguments for a paginated cubit request.
class PaginatedArgs with EquatableMixin {
  ///
  const PaginatedArgs({
    this.pageId = 0,
    required this.pageSize,
    this.searchQuery = '',
    this.isRefresh = false,
  });

  /// The page id.
  final int pageId;

  /// The page size.
  final int pageSize;

  /// The search query.
  final String searchQuery;

  /// A flag indicating whether the request is a refresh.
  final bool isRefresh;

  /// Copies the [PaginatedArgs] with the given parameters.
  PaginatedArgs copyWith({
    int? pageId,
    int? pageSize,
    String? searchQuery,
    bool? isRefresh,
  }) {
    return PaginatedArgs(
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
