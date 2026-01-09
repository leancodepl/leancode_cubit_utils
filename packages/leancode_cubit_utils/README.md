A collection of cubits and widgets that facilitate the creation of repetitive pages, eliminating boilerplate.

# Installation

Add dependency to your project:

```flutter pub add leancode_cubit_utils```

Import the package:

```import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';```


# Usage

The collection of utilities in the package can be divided into two subsets. [Single Request Utils](#single-request-utils) are used for creating pages where a single request is made to retrieve data which is then displayed. [Pagination Utils](#pagination-utils) are used for creating pages containing paginated lists. For both cases it is possible to implement variants that use different API clients. 

Implementation of cubits for handling [CQRS](https://pub.dev/packages/cqrs) queries is covered in [`leancode_cubit_utils_cqrs`][leancode_cubit_utils_cqrs]. 

## Single Request Utils

### `RequestCubit`

`RequestCubit` is used to execute a single API request. It has three generic arguments:
- `TRes` specifies what the request returns,
- `TOut` determines which model we want to emit as data in the state,
- `TError` defines error's type.

`HttpRequestCubit` in the example below provides the generic http implementation that can be used while defining all needed `RequestCubits`.

```dart
/// Base class for http request cubits.
abstract class HttpRequestCubit<TOut>
    extends RequestCubit<http.Response, TOut, int> {
  HttpRequestCubit(super.loggerTag, {required this.client});

  final http.Client client;

  /// Maps the given [data] to the output type [TOut].
  TOut map(String data);

  @override
  /// Client-specific method needed for handling the API response.
  Future<RequestState<TOut, int>> handleResult(
    http.Response result,
  ) async {
    if (result.statusCode == 200) {
      logger.info('Request success. Data: ${result.body}');
      return RequestSuccessState(map(result.body));
    } else {
      logger.severe('Request error. Status code: ${result.statusCode}');
      try {
        return await handleError(RequestErrorState(error: result.statusCode));
      } catch (e, s) {
        logger.severe(
          'Processing error failed. Exception: $e. Stack trace: $s',
        );
        return RequestErrorState(exception: e, stackTrace: s);
      }
    }
  }
}
```

Example implementation of `RequestCubit` using defined `HttpRequestCubit` looks like this:

```dart
class ProjectDetailsCubit extends HttpRequestCubit<ProjectDetailsDTO> {
  ProjectDetailsCubit({
    required super.client,
    required this.id,
  }) : super('ProjectDetailsCubit');

  final String id;

  @override
  // This method allows to map the given data into TOut.
  ProjectDetailsDTO map(String data) =>
      ProjectDetailsDTO.fromJson(jsonDecode(data) as Map<String, dynamic>);

  @override
  // In this method we should perform the request and return it in form of http.Response
  // which is then internally handled by handleResult.
  Future<http.Response> request() => client.get(Uri.parse('base-url/$id'));
}
```

The cubit itself handles the things like:
- emitting the corresponding state (loading, error, success, refresh),
- deduplication of the requests - you can decide whether, in the event that a user triggers sending a new request before the previous one is completed, you should abort the previous one or cancel the next one. You can set the `requestMode` when you create a single cubit, or you can set it globally using [`RequestLayoutConfigProvider`](#requestlayoutconfigprovider). By default it is set to ignore the next request while previous is being processed,
- refreshing - when you call the refresh() method, the cubit will re-execute the last request. If it already has the most recently retrieved data, it will be available,
- logging - you can observe what is happening inside of the cubit.

### `ArgsRequestCubit`
`ArgsRequestCubit<TArgs, TRes, TOut, TError>` is a version of `RequestCubit` in which the request method accepts an argument. `TArgs` determines the type of arguments accepted by the request method. `TRes`, `TOut` and `TError` serve the same purpose as in `RequestCubit`. 

If you call `refresh()` on `ArgsRequestCubit` it will perform a request with the last used arguments. They are also available under `lastRequestArgs` field.

### `RequestState`

`RequestState` represents the state of a request and can be one of the following:
- `RequestInitialState` - the request has not been started yet,
- `RequestLoadingState` - the request is currently being performed,
- `RequestSuccessState<TOut>` - the request completed successfully with data,
- `RequestErrorState<TError>` - the request failed with an error,
- `RequestRefreshState<TOut>` - the request is being refreshed while previous data is still available,
- `RequestEmptyState<TOut>` - the request completed successfully but returned empty data.

#### `map` method

`RequestState` provides a `map` method that allows you to transform the state into a value of any type. This is useful when you need to derive a value based on the current state without building a widget. The method accepts the following builders:

- `T Function()? onInitial` - called when the request is in its initial state. If not provided, falls back to `onLoading`,
- `T Function() onLoading` - called when the request is loading (required),
- `T Function(TOut? data) onSuccess` - called when the request completed successfully (required),
- `T Function(TError? err, Object? exception, StackTrace? st) onError` - called when the request failed (required),
- `T Function(TOut data)? onRefresh` - called when the request is refreshing with previous data. If not provided, falls back to `onSuccess`,
- `T Function(TOut? data)? onEmpty` - called when the request completed successfully but returned empty data. If not provided, falls back to `onSuccess`.

Example usage:

```dart
Scaffold(
  appBar: state.map<AppBar>(
    onLoading: () => const LoadingAppBar(),
    onSuccess: (data) => SuccessAppBar(data: data),
    onError: (err, exception, st) => const ErrorAppBar(error: err),
  ),
  body: YourPageContent(),
)
```

### `RequestCubitBuilder`

`RequestCubitBuilder` is a widget that builds a widget based on the current state of `BaseRequestCubit`. It takes numerous builders for each state:
- `WidgetBuilder? onInitial` - use it to show a widget before invoking the request for the first time.
- `WidgetBuilder? onLoading` - use it to show a loader widget while the request is being performed,
- `WidgetBuilder? onError` - use it to show error widget when processing the request fails,
- `RequestWidgetBuilder<TOut> onSuccess` - use it to build a page when the data is successfully loaded (required),
- `WidgetBuilder? onEmpty` - use it to show a widget when the request returns empty data. If not provided, falls back to global config or empty widget,
- `RequestWidgetBuilder<TOut>? onRefresh` - use it to show a widget while refreshing with previous data still available. If not provided, falls back to `onSuccess`.

Other than builders, you also need to provide the cubit based on which the `RequestCubitBuilder` will be rebuilt. You can also pass `onErrorCallback` which allows you to pass a callback to error widget builder. You may want to use it to implement a retry button.

Example usage of `RequestCubitBuilder`:
```dart
RequestCubitBuilder(
      cubit: context.read<ProjectDetailsCubit>(),
      onInitial: (context) => Center(
        child: ElevatedButton(
          onPressed: context.read<ProjectDetailsCubit>().run,
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
      onErrorCallback: context.read<ProjectDetailsCubit>().run,
      onSuccess: (context, data) {
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
      onRefresh: (context, data) {top
        return Stack(
          children: [
            ListView.builder(
              itemCount: data.assignments.length,
              itemBuilder: (context, index) {
                final assignment = data.assignments[index];
                return ListTile(
                  title: AppText(assignment.id),
                );
              },
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          ],
        );
      },
    )
```

As you may see `onLoading`, `onEmpty` and `onError` are marked as optional parameters. In many projects each of those widgets are the same for each page. So in order to eliminate even more boilerplate code, instead of passing them all each time you want to use `RequestCubitBuilder`, you can define them globally and provide in the whole app using [`RequestLayoutConfigProvider`](#requestlayoutconfigprovider).

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

## Pagination Utils
Pagination Utils were created to facilitate the creation of pages where the main element is a paginated list.

### `PaginatedCubit`

`PaginatedCubit` is used to handle the logic of retrieving the next pages of a paginated list. It has four generic arguments:
- [`TData`](#additional-data) represents additional data that we want to store and process along with the list items,
- `TRes` specifies what is returned from the API,
- `TResData` represents the structure in which items are returned from the API,
- `TItem` corresponds to the model of a single list item (after a potential transformation) that we plan to display as the element on the page. 

Example implementation of `PaginatedCubit` can look like this:
```dart
class IdentitiesCubit extends PaginatedCubit<void, http.Response,
    PaginatedResult<KratosIdentityDTO>, KratosIdentityDTO> {
  IdentitiesCubit({
    super.config,
    required this.api,
  }) : super(loggerTag: 'IdentitiesCubit');

  final Api api;

  @override
  Future<http.Response> requestPage(PaginatedArgs args) {
    return api.getIdentities(
      args.pageNumber,
      args.pageSize,
      args.searchQuery,
    );
  }

  @override
  RequestResult<PaginatedResult<KratosIdentityDTO>> handleResponse(
          http.Response res) =>
      res.statusCode == 200
          ? Success(PaginatedResult<KratosIdentityDTO>.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>))
          : Failure(res.statusCode);

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

You have to implement a body of three methods: `requestPage`, `handleResponse` and `onPageResult`. In the first one perform the request and return the response. In the second one, you need to transform the response into a result that can be handled by the third one that should return the result in form of `PaginatedResponse`. `PaginatedResponse` is a class which contains a list of elements called `items`, a `hasNextPage` flag determining whether there is a next page or not, you can optionally pass updated `data` which corresponds to additional data in this cubit. `PaginatedResponse` have to constructors:
- `PaginatedResponse.append` which will be sufficient in most of the cases. It appends passed items to the already fetched items,
- `PaginatedResponse.custom` gives you full control over the items. Items which you will pass to this constructor, will replace existing list of items.

The next step will be to use the `PaginatedCubitLayout` widget. It simplifies the construction of the layout for a paginated page.

### `PaginatedCubitLayout`
`PaginatedCubitLayout` is a widget used for building a page featuring a paginated list, and fetching next pages while scrolling. It takes two required arguments:

- `cubit` - an instance of `PaginatedCubit`,
- `itemBuilder` - builds a item widget from `TItem` object,

It also takes optional `controller`, `physics` and numerous optional builders:
- `separatorBuilder` - builds a separator widget.
- `headerBuilder` - builds a sliver widget on top the list which is scrolled together with the list,
- `footerBuilder` - builds a sliver widget under the list which is scrolled together with the list,
- `initialStateBuilder` - builds a widget that is displayed before the request for the first page is executed,
- `emptyStateBuilder` - builds a widget that is displayed when request executed successfully but no items were returned,
- `firstPageLoadingBuilder` - builds a widget that is displayed while fetching first page,
- `firstPageErrorBuilder` - builds a widget that is displayed when fetching first page fails, 
- `nextPageLoadingBuilder` - builds a widget which is displayed under the last element of the list while next page is being fetched,
- `nextPageErrorBuilder` - builds a widget which is displayed under the last element of the list if fetching the next page fails.

You can provide most of these builders globally in the whole app using [`PaginatedLayoutConfig`](#paginatedlayoutconfig).

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

#### `PreRequest`

`PreRequest` is a class that serves as an implementation of a pre-request. To utilize it, create an abstract base class that extends `PreRequest` and then create classes specific for each pre-request. An example base class: 

```dart
/// Base class for http pre-request use cases.
abstract class HttpPreRequest<TData, TItem>
    extends PreRequest<http.Response, String, TData, TItem> {
  @override
  /// This method performs the pre-request and returns the new state.
  Future<PaginatedState<TData, TItem>> run(
      PaginatedState<TData, TItem> state) async {
    try {
      final result = await request(state);

      if (result.statusCode == 200) {
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
```

Example implementation of `PreRequest` using defined `HttpPreRequest` looks like this:

```dart
class FiltersPreRequest extends HttpPreRequest<Filters, User> {
  FiltersPreRequest({required this.api});

  final Api api;

  @override
  Future<http.Response> request(PaginatedState<Filters, User> state) =>
      api.getFilters();

  @override
  Filters map(
    String res,
    PaginatedState<Filters, User> state,
  ) =>
      Filters.fromJson(jsonDecode(res) as Map<String, dynamic>);
}
```

Then you need to create an instance of defined `FiltersPreRequest` in `PaginatedCubit` constructor.


```dart 
class IdentitiesCubit extends PaginatedCubit<Filters, http.Response,
PaginatedResult<KratosIdentityDTO>, KratosIdentityDTO> {
  IdentitiesCubit({
    super.config,
    preRequest: FiltersPreRequest(api: api),// <--HERE
    required this.api,
  }) : super(loggerTag: 'IdentitiesCubit');

  /*Rest of the IdentitiesCubit implementation*/
}
```

If you provide a pre-request instance to `PaginatedCubit` it will take care of executing it before fetching the first page for the first time. If you want, you can change it so that the pre-request will be run each time before fetching the first page. You can do it locally for one cubit, or set it globally in the [config](#paginated-cubit-configuration).

### Additional Data

If there is a need to store any additional data along with the retrieved list items, `PaginatedCubit` is designed in a way that allows you to implement this within the same cubit. As you may have noticed, `PaginatedCubit` has four generic types. The first one, `TData`, corresponds to additional data which will be stored and processed within this cubit. It can for example be a list of selected filters or a set of selected list items. In case you don't want to use the additional data, you can simply pass `void` as the first generic type.

If you want to use this feature, define type of the data as the first generic type. Then you can access the data through the state. Here is an example implementation of PaginatedCubit with additional data which holds information about selected items:  

```dart
class IdentitiesCubit extends PaginatedCubit<List<KratosIdentityDTO>, http.Response,
PaginatedResult<KratosIdentityDTO>, KratosIdentityDTO> {
  IdentitiesCubit({
    super.config,
    required this.api,
  }) : super(loggerTag: 'IdentitiesCubit');

  final Api api;

  @override
  Future<http.Response> requestPage(PaginatedArgs args) { ... }

  @override
  RequestResult<PaginatedResult<KratosIdentityDTO>> handleResponse(http.Response res) { ... } 

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

[leancode_cubit_utils_cqrs]: https://pub.dev/packages/leancode_cubit_utils_cqrs
