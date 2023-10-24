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
//QueryCubit has two generic arguments, TRes and TOut. TRes specifies what the Query returns, while TOut determines which model we want to emit as data in the state.
class ProjectDetailsCubit extends QueryCubit<ProjectDetailsDTO, ProjectDetailsDTO> {
  ProjectDetailsCubit({
    required this.cqrs,
    required this.id,
  }) : super('ProjectDetailsCubit');

  final Cqrs cqrs;
  final String id;

  @override
  //This method allows to map the given TRes into TOut. 
  //In this case we don't want to change it, so we simply return the data.
  ProjectDetailsDTO map(ProjectDetailsDTO data) => data;

  @override
  //In this method we should perform the query and return it in form of QueryResult<TRes>.
  //QueryResult<TRes> is then internally handled by QueryCubit.
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
    onLoading: (BuildContext context) => const CircularProgressIndicator(),
    onError: (context, error, onErrorCallback) {
      return const Text(
        'Error',
        style: TextStyle(color: Colors.red),
      );
    },
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
TODO

## Other API Clients
TODO
