import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';

import '../utils/mocked_api.dart';

class TestPaginatedCubit extends PaginatedQueryCubit<void, Page<City>, City> {
  TestPaginatedCubit(
    this.api, {
    super.config,
  }) : super(loggerTag: 'TestPaginatedCubit');

  final ApiBase api;

  @override
  Future<QueryResult<Page<City>>> requestPage(PaginatedArgs args) {
    return api.getCities(
      args.pageNumber,
      args.pageSize,
      searchQuery: args.searchQuery,
    );
  }

  @override
  PaginatedResponse<List<CityType>, City> onPageResult(Page<City> page) {
    return PaginatedResponse.append(
      items: page.items,
      hasNextPage: page.hasNextPage,
    );
  }
}

class TestPreRequest
    extends QueryPreRequest<List<CityType>, List<CityType>, City> {
  TestPreRequest(this.api);

  final ApiBase api;

  @override
  Future<QueryResult<List<CityType>>> request(
    PaginatedState<List<CityType>, City> state,
  ) {
    return api.getTypes();
  }

  @override
  List<CityType> map(
    List<CityType> res,
    PaginatedState<List<CityType>, City> state,
  ) {
    return res;
  }
}

class TestPreRequestPaginatedCubit
    extends PaginatedQueryCubit<List<CityType>, Page<City>, City> {
  TestPreRequestPaginatedCubit(
    this.api, {
    super.preRequest,
    super.config,
  }) : super(loggerTag: 'TestPaginatedCubit', initialData: []);
  final ApiBase api;

  @override
  Future<QueryResult<Page<City>>> requestPage(PaginatedArgs args) {
    return api.getCities(
      args.pageNumber,
      args.pageSize,
      searchQuery: args.searchQuery,
    );
  }

  @override
  PaginatedResponse<List<CityType>, City> onPageResult(Page<City> page) {
    return PaginatedResponse.append(
      items: page.items,
      hasNextPage: page.hasNextPage,
    );
  }
}
