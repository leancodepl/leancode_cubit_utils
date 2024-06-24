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
