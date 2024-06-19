import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// An implementation of [PaginatedCubit] which handles [QueryResult] responses.
abstract class PaginatedQueryCubit<TData, TRes, TItem>
    extends PaginatedCubit<TData, QueryResult<TRes>, TRes, TItem> {
  /// Creates a new [PaginatedQueryCubit].
  PaginatedQueryCubit({
    required super.loggerTag,
    super.preRequest,
    super.config,
    super.initialData,
  });

  @override
  RequestResult<TRes> handleResponse(QueryResult<TRes> res) {
    return switch (res) {
      QuerySuccess(:final data) => Success<TRes>(data),
      QueryFailure(:final error) => Failure(error),
    };
  }
}
