import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_state.dart';
import 'package:leancode_cubit_utils/src/paginated/pre_request/pre_request.dart';

/// An implementation of [PreRequest] which handles [QueryResult] responses.
abstract class QueryPreRequest<TRes, TData, TItem>
    extends PreRequest<QueryResult<TRes>, TRes, TData, TItem> {
  @override
  Future<PaginatedState<TData, TItem>> run(
    PaginatedState<TData, TItem> state,
  ) async {
    try {
      return switch (await request(state)) {
        QuerySuccess(:final data) => state.copyWith(data: map(data, state)),
        QueryFailure(:final error) => handleError(state.copyWithError(error)),
      };
    } catch (e) {
      return state.copyWithError(e);
    }
  }
}
