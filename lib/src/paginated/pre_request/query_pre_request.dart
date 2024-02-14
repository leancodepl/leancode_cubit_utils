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
      final result = await request(state);
      if (result case QuerySuccess(:final data)) {
        return state.copyWith(
          data: map(data, state),
          preRequestSuccess: true,
        );
      } else if (result case QueryFailure(:final error)) {
        try {
          return handleError(state.copyWithError(error));
        } catch (e) {
          return state.copyWithError(e);
        }
      } else {
        return state.copyWithError();
      }
    } catch (e) {
      try {
        return handleError(state.copyWithError(e));
      } catch (e) {
        return state.copyWithError(e);
      }
    }
  }
}
