/// Configures the PaginatedCubits.
class PaginatedCubitConfig {
  /// The default page size used by all PaginatedCubits.
  static int get pageSize => _pageSize ?? 20;

  static set pageSize(int pageSize) => _pageSize = pageSize;

  static int? _pageSize;

  /// The default duration for run in PaginatedCubit when withDebounce is used.
  static Duration get runDebounce {
    return _runDebounce ?? const Duration(milliseconds: 500);
  }

  static set runDebounce(Duration runDebounce) => _runDebounce = runDebounce;

  static Duration? _runDebounce;

  /// The number of characters after which the search query will be sent.
  static int get searchBeginAt => _searchBeginAt ?? 3;

  static set searchBeginAt(int searchBeginAt) => _searchBeginAt = searchBeginAt;

  static int? _searchBeginAt;
}
