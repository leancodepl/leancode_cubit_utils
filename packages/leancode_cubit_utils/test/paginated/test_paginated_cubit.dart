import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

import '../utils/http_status_codes.dart';
import '../utils/mocked_api.dart';

class TestPaginatedCubit
    extends PaginatedCubit<void, http.Response, Page, City> {
  TestPaginatedCubit(
    this.api, {
    super.config,
  }) : super(loggerTag: 'TestPaginatedCubit');

  final ApiBase api;

  @override
  Future<http.Response> requestPage(PaginatedArgs args) {
    return api.getCities(
      args.pageNumber,
      args.pageSize,
      searchQuery: args.searchQuery,
    );
  }

  @override
  PaginatedResponse<List<CityType>, City> onPageResult(Page page) {
    return PaginatedResponse.append(
      items: page.cities,
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  RequestResult<Page> handleResponse(http.Response res) =>
      res.statusCode == StatusCode.ok.value
          ? Success(Page.fromJson(jsonDecode(res.body) as Json))
          : Failure(res.statusCode);
}

class TestPreRequest
    extends PreRequest<http.Response, List<CityType>, List<CityType>, City> {
  TestPreRequest(this.api);

  final ApiBase api;

  @override
  Future<http.Response> request(
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

  @override
  Future<PaginatedState<List<CityType>, City>> run(
    PaginatedState<List<CityType>, City> state,
  ) async {
    try {
      final result = await request(state);
      if (result.statusCode == StatusCode.ok.value) {
        return state.copyWith(
          data: map(
            CityType.allFromJson(
              jsonDecode(result.body) as Map<String, dynamic>,
            ),
            state,
          ),
          preRequestSuccess: true,
        );
      } else {
        try {
          return handleError(state.copyWithError(result.statusCode));
        } catch (e) {
          return state.copyWithError(e);
        }
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

class TestPreRequestPaginatedCubit
    extends PaginatedCubit<List<CityType>, http.Response, Page, City> {
  TestPreRequestPaginatedCubit(
    this.api, {
    super.preRequest,
    super.config,
  }) : super(loggerTag: 'TestPaginatedCubit', initialData: []);
  final ApiBase api;

  @override
  Future<http.Response> requestPage(PaginatedArgs args) {
    return api.getCities(
      args.pageNumber,
      args.pageSize,
      searchQuery: args.searchQuery,
    );
  }

  @override
  PaginatedResponse<List<CityType>, City> onPageResult(Page page) {
    return PaginatedResponse.append(
      items: page.cities,
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  RequestResult<Page> handleResponse(http.Response res) =>
      res.statusCode == StatusCode.ok.value
          ? Success(Page.fromJson(jsonDecode(res.body) as Json))
          : Failure(res.statusCode);
}
