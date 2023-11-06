A collection of cubits and widgets that facilitate the creation of repetitive pages, eliminating boilerplate. It contains an implementation that simplifies CQRS query handling, but it's also possible to connect with other API clients.

# Requirements

```cqrs: ">=10.0.1"```

# Installation

Add dependency to your project:

```flutter pub add leancode_cubit_utils```

Import the package:

```import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';```


# Usage

The collection of utilities in the package can be divided into two subsets. [Single Request Utils](#single-request-utils) are used for creating pages where a single request is made to retrieve data, which is then displayed. [Pagination Utils](#pagination-utils) are used for creating pages containing paginated lists. 

`leancode_cubit_utils` contains a complete implementation of Cubits for handling [CQRS](https://pub.dev/packages/cqrs) queries but for both cases it is possible to implement variants that use different API clients.

## Single Request Utils

### `QueryCubit`

`QueryCubit` is used to execute a single CQRS query. Example implementation of QueryCubit looks like this:

```dart
// QueryCubit has two generic arguments, TRes and TOut. TRes specifies what the Query returns, while TOut determines which model we 
// want to emit as data in the state.
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

The cubit itself handles the things like:
- emitting the corresponding state (loading, error, success, refresh),
- deduplication of the requests - you can decide whether, in the event that a user triggers sending a new request before the previous one is completed, you should abort the previous one or cancel the next one. You can set the `requestMode` when you create a single cubit, or you can set it globally using [`RequestLayoutConfigProvider`](#requestlayoutconfigprovider). By default it is set to ignore the next request while previous is being processed,
- refreshing - when you call the refresh() method, the cubit will re-execute the last request. If it already has the most recently retrieved data, it will be available,
- logging - you can observe what is happening inside of the cubit.

### `ArgsQueryCubit`
`ArgsQueryCubit<TArgs, TRes, TOut>` is a version of `QueryCubit` in which the request method accepts an argument. `TArgs` determines the type of arguments accepted by the request method. `TRes` and `TOut` serve the same purpose as in `QueryCubit`. 

If you call `refresh()` on `ArgsQueryCubit` it will perform a query with the last used arguments. They are also available under `lastRequestArgs` field.

### `RequestCubitBuilder`

`RequestCubitBuilder` is a widget that builds a widget based on the current state of `BaseRequestCubit`. It takes a numerous builders for each state:
- `WidgetBuilder? onInitial` - use it to show a widget before invoking the request for the first time,
- `WidgetBuilder? onLoading` - use it to show a loader widget while the request is being performed,
- `WidgetBuilder? onError` - use it to show error widget when processing the request fails,
- `RequestWidgetBuilder<TOut> builder` - use it to build a page when the data is successfully loaded. 

Other than builders, you also need to provide the cubit based on which the `RequestCubitBuilder` will be rebuilt. And you can also pass `onErrorCallback` which allows you to pass a callback to error widget builder. You may want to use it to implement retry button.

Example usage of `RequestCubitBuilder`:
```dart
RequestCubitBuilder(
      cubit: context.read<ProjectDetailsCubit>(),
      onInitial: (context) => Center(
        child: ElevatedButton(
          onPressed: context.read<ProjectDetailsCubit>().get,
          child: const AppText('Fetch the data'),
        ),
      ),
      onLoading: (context) => const Center(child: CircularProgressIndicator()),
      onError: (context, error, retry) => Center(
        child: ElevatedButton(
          onPressed: retry,
          child: const AppText('Retry'),
        ),
      ),
      onErrorCallback: context.read<ProjectDetailsCubit>().get,
      builder: (context, data) {
        return ListView.builder(
          itemCount: data.assignments.length,
          itemBuilder: (context, index) {
            final assignment = data.assignments[index];
            return ListTile(
              title: AppText(assignment.id),
            );
          },
        );
      },
    )
```

As you may see `onInitial`, `onLoading` and `onError` are marked as optional parameter. In many projects each of those widgets are the same for each page. So in order to eliminate even more boilerplate code, instead of passing them all each time you want to use `RequestCubitBuilder`, you can define them globally and provider in the whole app using [`RequestLayoutConfigProvider`](#requestlayoutconfigprovider).

### `RequestLayoutConfigProvider`

`RequestLayoutConfigProvider` is a widget which creates a default configuration with passed builders and `requestMode` and provides it to all the descendants. 

```dart
RequestLayoutConfigProvider(
    requestMode: RequestMode.replace,
    onLoading: (BuildContext context) => const YourDefaultLoader(),
    onError: (context, error, onErrorCallback) => const YourDefaultErrorWidget(),
    child: const MainApp(),
  )
```

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


## Pagination Utils
Pagination Utils were created to facilitate the creation of pages where the main element is a paginated list.

### `PaginatedQueryCubit`

`PaginatedQueryCubit<TData, TRes, TItem>` is a implementation of `PaginatedCubit` for CQRS. It is used to handle the logic of retrieving the next pages of a paginated list. It has three generic argument:
- [`TData`](#additional-data) represents additional data that we want to store and process along with the list items,
- `TRes` represents the structure in which items list are returned from the API,
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

You have to implement a body of two methods: `requestPage` and `onPageResult`. In first one perform the request and return it's result. In the second one, you need to handle te result and return it in form of `PaginatedResponse`. `PaginatedResponse` it's a class which contains a list of elements called `items`, a `hasNextPage` flag determining whether there is a next page or not, and you can also optionally pass updated `data` which corresponds to additional data in this cubit. `PaginatedResponse` have to constructors:
- `PaginatedResponse.append` which will be sufficient in most of the cases. It appends passed items to the already fetched items,
- `PaginatedResponse.custom` gives you full control over the items. Items which you will pass to this constructor, will replace existing list of items.

The next step will be to use the `PaginatedCubitLayout` widget. It simplifies the construction of the layout for a paginated page.

### `PaginatedCubitLayout`
`PaginatedCubitLayout` is a widget used for building a page featuring a paginated list, and fetching next pages while scrolling. It takes two required arguments:

- `cubit` - an instance of `PaginatedCubit`,
- `itemBuilder` - builds a item widget from `TItem` object,

It also takes optional `controller`, `physics`, `padding` and numerous optional builders:
- `separatorBuilder` - builds a separator widget.
- `headerBuilder` - builds a sliver widget on top the list which is scrolled together with the list,
- `footerBuilder` - builds a sliver widget under the list which is scrolled together with the list,
- `initialStateBuilder` - builds a widget that is displayed before the request for the first page is executed,
- `emptyStateBuilder` - builds a widget that is displayed when request executed successfully but no items were returned,
- `firstPageLoadingBuilder` - builds a widget that is displayed while fetching first page,
- `firstPageErrorBuilder` - builds a widget that is displayed when fetching first page fails, 
- `nextPageLoadingBuilder` - builds a widget which is displayed under the last element of the list while next page is being fetched,
- `nextPageErrorBuilder` - builds a widget which is displayed under the last element of the list if fetching the next page fails.

You can provider most of those builder globally in the whole app using [`PaginatedLayoutConfig`](#paginatedlayoutconfig).

### `PaginatedCubitBuilder`
`PaginatedCubitBuilder` is a widget which rebuilds itself when state of the paginated cubit changes. It takes two required parameter:

- `builder` - a callback that builds a child based on the current state. It is rebuild anytime the state changes,
- `cubit` - an instance of `PaginatedCubit`.

### Paginated Cubit Configuration

`leancode_cubit_utils` allows configuring various parameters related to paginated lists:
- `pageSize` - size of single page. Defaults to 20,
- `searchBeginAt` - number of characters which needs to be inserted to start searching. Defaults to 3,  
- `runDebounce` - debounce duration for running the fetchNextPage method if `withDebounce` is used. Defaults to 500 milliseconds,
- `firstPageIndex` - index of a page which will be fetched as a first. Defaults to 0,
- `searchDebounce` - debounce duration for search. Defaults to 500 milliseconds,
- `preRequestMode` - determines whether the pre-request should be run only once. Or every time the first page is fetched. (Read more about it in [Pre-request section](#pre-request)).

Each of these parameters can be set individually for a specific cubit when creating it, or you can define them globally by using the `PaginatedConfigProvider`.

### `PaginatedLayoutConfig`

`PaginatedLayoutConfig` allows you to globally define loaders, error widgets, and empty state widget, so you don't have to specify them each time you use `PaginatedCubitLayout`. This makes it more convenient and efficient to configure the visual elements and behavior of your paginated layouts across your application.

```dart
PaginatedLayoutConfig(
    initialStateBuilder: (context, state) => YourDefaultEmptyStateWidget(), 
    firstPageLoadingBuilder: (context, state) => const YourDefaultLoader(),
    nextPageLoadingBuilder: (context, state) => const YourDefaultLoader(),
    firstPageErrorBuilder: (context, error, retry) => const YourDefaultErrorWidget(),
    nextPageErrorBuilder: (context, error, retry) => const YourDefaultErrorWidget(),
    child: const MainApp(),
  )
```

### Searching

In case you need a search functionality you may use the built in support in `PaginatedCubit` for this purpose. To use it, add a text field on the page that will modify the search query using `updateSearchQuery` method. After meeting all the conditions (i.e., debounce time has passed and the required number of characters has been entered), the cubit will execute a request for the first page, and you will find the searched phrase in the arguments which you can handle inside `requestPage` method in your implementation of `PaginatedCubit`.

You can configure search debounce time and number of characters which needs to be inserted to start searching. In order to do it read about [Paginated Cubit Configuration](#paginated-cubit-configuration).

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
  AdditionalData map(
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

If you provide a pre-request instance to `PaginatedCubit` it will take care of executing it before fetching the first page for the first time. If you want, you can change it so that the pre-request will be run each time before fetching the first page. You can do it locally for one cubit, or set it globally in the [config](#paginated-cubit-configuration).

### Additional Data

If there is a need to store any additional data along with the retrieved list items, `PaginatedCubit` is designed in a way that allows you to implement this within the same cubit. As you may have noticed, `PaginatedQueryCubit` has three generic types. The first one, `TData`, corresponds to additional data which will be stored and processed within this cubit. It can for example be a list of selected filters or a set of selected list items. In case you don't want to use the additional data, you can simply pass `void` as the first generic type.

If you want to use this feature, define type of the data as the first generic type. Then you can access the data through the state. Here is an example implementation of PaginatedCubit with additional data which holds information about selected items:  

```dart
class IdentitiesCubit extends PaginatedQueryCubit<List<KratosIdentityDTO>,
PaginatedResult<KratosIdentityDTO>, KratosIdentityDTO> {
  IdentitiesCubit({
    super.config,
    required this.cqrs,
  }) : super(loggerTag: 'IdentitiesCubit');

  final Cqrs cqrs;

  @override
  Future<QueryResult<PaginatedResult<KratosIdentityDTO>>> requestPage(PaginatedArgs args) { ... }

  @override
  PaginatedResponse<void, KratosIdentityDTO> onPageResult(PaginatedResult<KratosIdentityDTO> page) { ... }

  void onTilePressed(KratosIdentityDTO item) {
    final selectedIdentity = state.data ?? {};
    emit(
      state.copyWith(
        data: selectedIdentity.contains(item)
            ? selectedIdentity.difference({item})
            : selectedIdentity.union({item}),
      ),
    );
  } 
}
```