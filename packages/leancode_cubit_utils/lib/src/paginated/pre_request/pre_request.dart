import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// Enum defining weather the pre-request should be run once or each time the
/// first page is loaded.
enum PreRequestMode {
  /// The pre-request should be run once before the first page is loaded.
  once,

  /// The pre-request should be run each time the first page is loaded.
  each,
}

/// Base class for all pre-request use cases.
abstract class PreRequest<TRes, TResData, TData, TItem> {
  /// Performs the pre-request and returns the new state.
  Future<PaginatedState<TData, TItem>> run(PaginatedState<TData, TItem> state);

  /// Executes the use case.
  Future<TRes> request(PaginatedState<TData, TItem> state);

  /// Map newly loaded data.
  TData map(TResData res, PaginatedState<TData, TItem> state);

  /// A method which allows to handle error in a custom way and return a new
  /// state.
  PaginatedState<TData, TItem> handleError(PaginatedState<TData, TItem> state) {
    return state;
  }
}
