import 'package:cqrs/cqrs.dart';
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
  }) {
    return AdditionalData(
      availableFilters: availableFilters ?? this.availableFilters,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      selectedUsers: selectedUsers ?? this.selectedUsers,
    );
  }
}

class FiltersPreRequest extends PreRequest<Filters, AdditionalData, User> {
  FiltersPreRequest({
    required this.api,
  });

  final MockedApi api;

  @override
  Future<QueryResult<Filters>> request(
    PaginatedState<AdditionalData, User> state,
  ) {
    return api.getFilters();
  }

  @override
  AdditionalData map(
    Filters res,
    PaginatedState<AdditionalData, User> state,
  ) {
    return AdditionalData(
      availableFilters: res.availableFilters,
      selectedFilters: state.data?.selectedFilters
              .where((e) => res.availableFilters.contains(e))
              .toSet() ??
          {},
    );
  }
}

class SimplePaginatedCubit
    extends PaginatedCubit<Filters, AdditionalData, Page<User>, User> {
  SimplePaginatedCubit(this.api)
      : super(
          loggerTag: 'SimplePaginatedCubit',
          preRequest: FiltersPreRequest(api: api),
          config: PaginatedConfigProvider.config.copyWith(pageSize: 15),
        );

  final MockedApi api;

  @override
  Future<QueryResult<Page<User>>> requestPage(PaginatedArgs args) {
    return api.getUsers(
      args.pageNumber,
      args.pageSize,
      selectedFilters: state.data?.selectedFilters.toList() ?? [],
      searchQuery: args.searchQuery,
    );
  }

  @override
  PaginatedResponse<AdditionalData, User> onPageResult(Page<User> page) {
    return PaginatedResponse(
      items: state.isFirstPage ? page.items : [...state.items, ...page.items],
      hasNextPage: page.hasNextPage,
      data: state.data,
    );
  }

  Future<void> onFilterPressed(Filter filter) async {
    final selectedFilters = state.data?.selectedFilters;
    if (selectedFilters == null) {
      return;
    }

    emit(
      state.copyWith(
        data: state.data?.copyWith(
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
    final selectedUsers = state.data?.selectedUsers;
    if (selectedUsers == null) {
      return;
    }
    emit(
      state.copyWith(
        data: state.data?.copyWith(
          selectedUsers: switch (selectedUsers.contains(user)) {
            true => selectedUsers.difference({user}),
            false => selectedUsers.union({user}),
          },
        ),
      ),
    );
  }
}
