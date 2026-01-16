## 0.5.0

* **BREAKING CHANGE:** Remove `useQueryWithEmptyCubit` and `SimpleQueryWithEmptyCubit`.
* **BREAKING CHANGE:** Remove `useArgsQueryWithEmptyCubit` and `SimpleArgsQueryWithEmptyCubit`.
* Start using `isEmpty` checker of `useQueryCubit` and pass it `SimpleQueryCubit`.
* Add `isEmpty` checker to `useArgsQueryCubit` and `SimpleArgsQueryCubit`.

## 0.4.0

* Update `leancode_cubit_utils` dependency to `^0.4.0` (includes breaking change: `builder` parameter renamed to `onSuccess` in `RequestCubitBuilder`)

## 0.3.1

* Upgrade `bloc` to ^9.0.0

## 0.3.0

* Use `leancode_cubit_utils` version `0.3.1`

## 0.2.0

* Add:
    - `SimpleQueryWithEmptyCubit`
    - `useQueryWithEmptyCubit`
    - `SimpleArgsQueryWithEmptyCubit`
    - `useArgsQueryWithEmptyCubit`

## 0.1.0

* Extract cqrs support from the `leancode_cubit_utils` package.
