import 'dart:convert';

import 'package:example/http/status_codes.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:example/pages/paginated/api.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class AdditionalData with EquatableMixin {
  AdditionalData({
    this.availableFilters = const [],
    this.selectedFilters = const {},
    this.selectedUsers = const {},
  });

  final List<Filter> availableFilters;
  final Set<Filter> selectedFilters;
  final Set<User> selectedUsers;

  @override
  List<Object?> get props => [
        availableFilters,
        selectedFilters,
        selectedUsers,
      ];

  AdditionalData copyWith({
    List<Filter>? availableFilters,
    Set<Filter>? selectedFilters,
    Set<User>? selectedUsers,
  }) =>
      AdditionalData(
        availableFilters: availableFilters ?? this.availableFilters,
        selectedFilters: selectedFilters ?? this.selectedFilters,
        selectedUsers: selectedUsers ?? this.selectedUsers,
      );
}

class FiltersPreRequest
    extends PreRequest<http.Response, String, AdditionalData, User> {
  FiltersPreRequest({
    required this.api,
  });

  final MockedApi api;

  @override
  Future<http.Response> request(
    PaginatedState<AdditionalData, User> state,
  ) =>
      api.getFilters();

  @override
  AdditionalData map(
    String res,
    PaginatedState<AdditionalData, User> state,
  ) {
    final filters = Filters.fromJson(jsonDecode(res) as Map<String, dynamic>);

    return AdditionalData(
      availableFilters: filters.availableFilters,
      selectedFilters: state.data.selectedFilters
          .where((e) => filters.availableFilters.contains(e))
          .toSet(),
    );
  }

  @override
  Future<PaginatedState<AdditionalData, User>> run(
      PaginatedState<AdditionalData, User> state) async {
    try {
      final result = await request(state);

      if (result.statusCode == StatusCode.ok.value) {
        return state.copyWith(
          data: map(result.body, state),
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

class SimplePaginatedCubit
    extends PaginatedCubit<AdditionalData, http.Response, Page, User> {
  SimplePaginatedCubit(this.api)
      : super(
          loggerTag: 'SimplePaginatedCubit',
          preRequest: FiltersPreRequest(api: api),
          config: PaginatedConfigProvider.config.copyWith(pageSize: 15),
          initialData: AdditionalData(),
        );

  final MockedApi api;

  @override
  Future<http.Response> requestPage(PaginatedArgs args) => api.getUsers(
        args.pageNumber,
        args.pageSize,
        selectedFilters: state.data.selectedFilters.toList(),
        searchQuery: args.searchQuery,
      );

  @override
  PaginatedResponse<AdditionalData, User> onPageResult(Page page) =>
      PaginatedResponse.append(
        items: page.users,
        hasNextPage: page.hasNextPage,
      );

  Future<void> onFilterPressed(Filter filter) async {
    final selectedFilters = state.data.selectedFilters;

    emit(
      state.copyWith(
        data: state.data.copyWith(
          selectedFilters: switch (selectedFilters.contains(filter)) {
            true => selectedFilters.difference({filter}),
            false => selectedFilters.union({filter}),
          },
        ),
      ),
    );

    return fetchNextPage(state.args.firstPageIndex, withDebounce: true);
  }

  void onTilePressed(User user) {
    final selectedUsers = state.data.selectedUsers;

    emit(
      state.copyWith(
        data: state.data.copyWith(
          selectedUsers: switch (selectedUsers.contains(user)) {
            true => selectedUsers.difference({user}),
            false => selectedUsers.union({user}),
          },
        ),
      ),
    );
  }

  @override
  RequestResult<Page> handleResponse(http.Response res) =>
      res.statusCode == StatusCode.ok.value
          ? Success(Page.fromJson(jsonDecode(res.body) as Map<String, dynamic>))
          : Failure(res.statusCode);
}
