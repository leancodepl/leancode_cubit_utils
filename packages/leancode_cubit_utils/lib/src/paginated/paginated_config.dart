import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// Configures the parameters in PaginatedCubits.
class PaginatedConfig {
  /// Creates a new instance of PaginatedConfig.
  PaginatedConfig({
    this.pageSize = 20,
    this.runDebounce = const Duration(milliseconds: 500),
    this.searchBeginAt = 3,
    this.firstPageIndex = 0,
    this.searchDebounce = const Duration(milliseconds: 500),
    this.preRequestMode = PreRequestMode.once,
  });

  /// The page size. Defaults to 20.
  final int pageSize;

  /// The debounce duration for running the fetchNextPage method if withDebounce
  /// is used. Defaults to 500 milliseconds.
  final Duration runDebounce;

  /// The minimum length of the search query to begin searching. Defaults to 3.
  final int searchBeginAt;

  /// The first page index. Defaults to 0.
  final int firstPageIndex;

  /// The debounce duration for search. Defaults to 500 milliseconds.
  final Duration searchDebounce;

  /// The pre-request mode. Defaults to PreRequestMode.once.
  final PreRequestMode preRequestMode;

  /// Creates a copy of this instance with the given fields replaced with the
  /// new values.
  PaginatedConfig copyWith({
    int? pageSize,
    Duration? runDebounce,
    int? searchBeginAt,
    int? firstPageIndex,
    Duration? searchDebounce,
    PreRequestMode? preRequestMode,
  }) {
    return PaginatedConfig(
      pageSize: pageSize ?? this.pageSize,
      runDebounce: runDebounce ?? this.runDebounce,
      searchBeginAt: searchBeginAt ?? this.searchBeginAt,
      firstPageIndex: firstPageIndex ?? this.firstPageIndex,
      searchDebounce: searchDebounce ?? this.searchDebounce,
      preRequestMode: preRequestMode ?? this.preRequestMode,
    );
  }
}

/// Provides the default configuration for all PaginatedCubits.
class PaginatedConfigProvider {
  /// The default configuration used by all PaginatedCubits.
  static PaginatedConfig get config => _config ?? PaginatedConfig();

  static set config(PaginatedConfig config) => _config = config;

  static PaginatedConfig? _config;
}
