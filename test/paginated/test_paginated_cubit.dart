import 'package:cqrs/src/cqrs_result.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_args.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_cubit.dart';

import '../utils/mocked_api.dart';

class TestPaginatedCubit extends PaginatedCubit<void, void, Page<City>, City> {
  TestPaginatedCubit(
    this.api, {
    super.config,
  }) : super(loggerTag: 'TestPaginatedCubit');
  final ApiBase api;

  @override
  PaginatedResponse<void, City> onPageResult(Page<City> page) {
    //TODO: Simplify mapping page result. Implementation should not require developer
    // to append new list to existing list.
    return PaginatedResponse(
      items: state.isFirstPage ? page.items : [...state.items, ...page.items],
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  Future<QueryResult<Page<City>>> requestPage(PaginatedArgs args) {
    return api.getCities(
      args.pageNumber,
      args.pageSize,
      searchQuery: args.searchQuery,
    );
  }
}

class TestPreRequest extends PreRequest<List<CityType>, List<CityType>, City> {
  TestPreRequest(this.api);

  final ApiBase api;

  @override
  List<CityType> map(
    List<CityType> res,
    PaginatedState<List<CityType>, City> state,
  ) {
    return res;
  }

  @override
  Future<QueryResult<List<CityType>>> request(
    PaginatedState<List<CityType>, City> state,
  ) {
    return api.getTypes();
  }
}

class TestPreRequestPaginatedCubit
    extends PaginatedCubit<List<CityType>, List<CityType>, Page<City>, City> {
  TestPreRequestPaginatedCubit(
    this.api, {
    super.preRequest,
    super.config,
  }) : super(loggerTag: 'TestPaginatedCubit');
  final ApiBase api;

  @override
  PaginatedResponse<List<CityType>, City> onPageResult(Page<City> page) {
    return PaginatedResponse(
      items: state.isFirstPage ? page.items : [...state.items, ...page.items],
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  Future<QueryResult<Page<City>>> requestPage(PaginatedArgs args) {
    return api.getCities(
      args.pageNumber,
      args.pageSize,
      searchQuery: args.searchQuery,
    );
  }
}
