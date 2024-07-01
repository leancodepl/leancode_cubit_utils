An extension of [`leancode_cubit_utils`][leancode_cubit_utils]. A collection of cubits and widgets that facilitate the creation of repetitive pages, eliminating boilerplate. It contains an implementation that simplifies CQRS query handling. For the full documentation and other API clients please refer to [`leancode_cubit_utils`][leancode_cubit_utils].

# Requirements

```cqrs: ">=10.0.1"```

# Installation

Add dependency to your project:

```flutter pub add leancode_cubit_utils_cqrs```

Import the package:

```import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';```


# Usage

`leancode_cubit_utils_cqrs` contains a complete implementation of cubits for handling [CQRS](https://pub.dev/packages/cqrs) queries for both [Single Request Utils](#single-request-utils) and [Pagination Utils](#pagination-utils).

## Single Request Utils

### `QueryCubit`

`QueryCubit` is used to execute a single CQRS query. Example implementation of QueryCubit looks like this:

```dart
// QueryCubit has two generic arguments, TRes and TOut. TRes specifies what the Query returns, while TOut determines which model we want to emit as data in the state.
class ProjectDetailsCubit extends QueryCubit<ProjectDetailsDTO, ProjectDetailsDTO> {
  ProjectDetailsCubit({
    required this.cqrs,
    required this.id,
  }) : super('ProjectDetailsCubit');

  final Cqrs cqrs;
  final String id;

  @override
  // This method allows to map the given TRes into TOut. 
  // In this case we don't want to change it, so we simply return the data.
  ProjectDetailsDTO map(ProjectDetailsDTO data) => data;

  @override
  // In this method we should perform the query and return it in form of QueryResult<TRes>.
  // QueryResult<TRes> is then internally handled by QueryCubit.
  Future<QueryResult<ProjectDetailsDTO>> request() {
    return cqrs.get(ProjectDetails(id: id));
  }
}
```

### `ArgsQueryCubit`
`ArgsQueryCubit<TArgs, TRes, TOut>` is a version of `QueryCubit` in which the request method accepts an argument. `TArgs` determines the type of arguments accepted by the request method. `TRes` and `TOut` serve the same purpose as in `QueryCubit`.

## `useQueryCubit`, `useArgsQueryCubit`

Sometimes, there is no need to map the query response in any way. In such cases, there's no necessity to implement a cubit extending `QueryCubit`/`ArgsQueryCubit`. Instead, you can use one of the provided hooks, `useQueryCubit` or `useArgsQueryCubit`. Simply provide the request to be executed, and you will receive a cubit that you can then use in the same way by passing it to the `RequestCubitBuilder`.

```dart
final queryCubit = useQueryCubit(
    () => cqrs.get(ProjectDetails(id: id)),
);

final argsQueryCubit = useArgsQueryCubit(
    (args) => cqrs.get(AllProjects(sortByNameDescending: args.isDescending)),
);
```

You may still configure `requestMode` and `loggerTag` by passing optional parameters. In `useQueryCubit` you can also define whether you want to invoke the request right away or not by passing `callOnCreate` flag.

## `SimpleQueryCubit`, `SimpleArgsQueryCubit`

`SimpleQueryCubit` and `SimpleArgsQueryCubit` are simplified implementation of `QueryCubit` and `ArgsQueryCubit` in case mapping the response is not needed. They were created for `useQueryCubit` and `useArgsQueryCubit` but can be used independently.


## Pagination Utils
Pagination Utils were created to facilitate the creation of pages where the main element is a paginated list.

### `PaginatedQueryCubit`

`PaginatedQueryCubit<TData, TRes, TItem>` is an implementation of `PaginatedCubit` for CQRS. It is used to handle the logic of retrieving the next pages of a paginated list. It has three generic arguments:
- `TData` represents additional data that we want to store and process along with the list items,
- `TRes` represents the structure in which items are returned from the API,
- `TItem` corresponds to the model of a single list item (after a potential transformation) that we plan to display as the element on the page. 

Example implementation of `PaginatedQueryCubit` can look like this:
```dart
class IdentitiesCubit extends PaginatedQueryCubit<void, PaginatedResult<KratosIdentityDTO>, KratosIdentityDTO> {
  IdentitiesCubit({
    super.config,
    required this.cqrs,
  }) : super(loggerTag: 'IdentitiesCubit');

  final Cqrs cqrs;

  @override
  Future<QueryResult<PaginatedResult<KratosIdentityDTO>>> requestPage(
    PaginatedArgs args,
  ) {
    return cqrs.get(
      // Query fetching next page
      SearchIdentities(
        pageSize: args.pageSize,
        pageNumber: args.pageNumber,
        emailPattern: args.searchQuery,
      ),
    );
  }

  @override
  PaginatedResponse<void, KratosIdentityDTO> onPageResult(
    PaginatedResult<KratosIdentityDTO> page,
  ) {
    // Use cubit method to calculate if there is a next page
    final args = state.args;
    final hasNextPage = calculateHasNextPage(
      pageNumber: args.pageNumber,
      totalCount: page.totalCount,
      );

    // Return the response with the next page appended
    return PaginatedResponse.append(
      items: page.items,
      hasNextPage: hasNextPage,
    );
  }
}
```

You have to implement a body of two methods: `requestPage` and `onPageResult`. In the first one perform the request and return it's result. In the second one, you need to handle te result and return it in form of `PaginatedResponse`. 

### Pre-request
Pre-requests allow you to perform an operation before making a request for the first page. This could be, for example, fetching available filters.

#### `QueryPreRequest`

`QueryPreRequest` is a class that serves as an implementation of a pre-request specifically designed for CQRS. To utilize the pre-request feature provided by this functionality, create a class that extends `QueryPreRequest`.

```dart
class FiltersPreRequest extends QueryPreRequest<List<Filter>, List<Filter>, User> {
  FiltersPreRequest({required this.cqrs});

  final Cqrs cqrs;

  @override
  Future<QueryResult<List<Filter>>> request(PaginatedState<List<Filter>, User> state) {
    return api.getFilters();
  }

  @override
  List<Filter> map(
    List<Filter> res,
    PaginatedState<List<Filter>, User> state,
  ) {
    return res;
  }
}
```

Then you need to create an instance of defined `FiltersPreRequest` in `PaginatedCubit` constructor.


```dart 
class IdentitiesCubit extends PaginatedQueryCubit<List<Filter>,
PaginatedResult<KratosIdentityDTO>, KratosIdentityDTO> {
  IdentitiesCubit({
    super.config,
    preRequest: FiltersPreRequest(cqrs: cqrs),// <--HERE
    required this.cqrs,
  }) : super(loggerTag: 'IdentitiesCubit');

  /*Rest of the IdentitiesCubit implementation*/
}
```

[leancode_cubit_utils]: https://pub.dev/packages/leancode_cubit_utils
