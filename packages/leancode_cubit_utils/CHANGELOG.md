## 0.5.0

* **BREAKING CHANGE**: Remove `map` and `isEmpty` methods from `RequestCubit`.
* **BREAKING CHANGE**: Remove `TData` generic parameter from `RequestCubit`.
* Add `map` method to `RequestState`.
* Add `onRefreshing` callback to `RequestCubitBuilder`.
* **BREAKING CHANGE**: Make `data` in `RequestRefreshingState` non-nullable.
* **BREAKING CHANGE**: Add `data` to `RequestEmptyState`.
* **BREAKING CHANGE**: Rename `RequestRefreshState` to `RequestRefreshingState`

## 0.4.2

* Upgrade `leancode_hooks` to 0.1.2.
* Upgrade `leancode_lint` to 18.0.0.

## 0.4.1

* Upgrade `provider` to ^6.1.5

## 0.4.0

* **BREAKING CHANGE**: Rename `builder` parameter to `onSuccess` in `RequestCubitBuilder`

## 0.3.2

* Upgrade `bloc` to ^9.0.0

## 0.3.1

* Rename `headerBuilder` and `footerBuilder` to `headerSliverBuilder` and `footerSliverBuilder` in `PaginatedCubitLayout`
* Rebuild `headerSliverBuilder` and `footerSliverBuilder` on `PaginatedCubit` state change

## 0.3.0

* Export `RequestCubitConfig` from `leancode_cubit_utils.dart`

## 0.2.0

* Add `isEmpty` to `BaseRequestCubit`

## 0.1.0

* Extract `cqrs` support to `leancode_cubit_utils_cqrs`
* Provide http example

## 0.0.4

* Remove unused, unexported code from `query` directory

## 0.0.3

* Make `retry` in `RequestErrorBuilder` and `PaginatedErrorBuilder` non-nullable

## 0.0.2

* Add default `onErrorCallback` for `RequestCubitBuilder`
* Change `PaginatedCubitLayout` first page error callback from `cubit.run` to `cubit.refresh`

## 0.0.1

* Initial version containing utilities for creating paginated page and page for performing a single request on a page.
