// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaginatedStateCWProxy<TItem> {
  PaginatedState<TItem> type(PaginatedStateType type);

  PaginatedState<TItem> searchQuery(String searchQuery);

  PaginatedState<TItem> items(List<TItem> items);

  PaginatedState<TItem> pageSize(int pageSize);

  PaginatedState<TItem> pageId(int pageId);

  PaginatedState<TItem> hasNextPage(bool hasNextPage);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PaginatedState<TItem>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PaginatedState<TItem>(...).copyWith(id: 12, name: "My name")
  /// ````
  PaginatedState<TItem> call({
    PaginatedStateType? type,
    String? searchQuery,
    List<TItem>? items,
    int? pageSize,
    int? pageId,
    bool? hasNextPage,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPaginatedState.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPaginatedState.copyWith.fieldName(...)`
class _$PaginatedStateCWProxyImpl<TItem>
    implements _$PaginatedStateCWProxy<TItem> {
  const _$PaginatedStateCWProxyImpl(this._value);

  final PaginatedState<TItem> _value;

  @override
  PaginatedState<TItem> type(PaginatedStateType type) => this(type: type);

  @override
  PaginatedState<TItem> searchQuery(String searchQuery) =>
      this(searchQuery: searchQuery);

  @override
  PaginatedState<TItem> items(List<TItem> items) => this(items: items);

  @override
  PaginatedState<TItem> pageSize(int pageSize) => this(pageSize: pageSize);

  @override
  PaginatedState<TItem> pageId(int pageId) => this(pageId: pageId);

  @override
  PaginatedState<TItem> hasNextPage(bool hasNextPage) =>
      this(hasNextPage: hasNextPage);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PaginatedState<TItem>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PaginatedState<TItem>(...).copyWith(id: 12, name: "My name")
  /// ````
  PaginatedState<TItem> call({
    Object? type = const $CopyWithPlaceholder(),
    Object? searchQuery = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? pageSize = const $CopyWithPlaceholder(),
    Object? pageId = const $CopyWithPlaceholder(),
    Object? hasNextPage = const $CopyWithPlaceholder(),
  }) {
    return PaginatedState<TItem>(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PaginatedStateType,
      searchQuery:
          searchQuery == const $CopyWithPlaceholder() || searchQuery == null
              ? _value.searchQuery
              // ignore: cast_nullable_to_non_nullable
              : searchQuery as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TItem>,
      pageSize: pageSize == const $CopyWithPlaceholder() || pageSize == null
          ? _value.pageSize
          // ignore: cast_nullable_to_non_nullable
          : pageSize as int,
      pageId: pageId == const $CopyWithPlaceholder() || pageId == null
          ? _value.pageId
          // ignore: cast_nullable_to_non_nullable
          : pageId as int,
      hasNextPage:
          hasNextPage == const $CopyWithPlaceholder() || hasNextPage == null
              ? _value.hasNextPage
              // ignore: cast_nullable_to_non_nullable
              : hasNextPage as bool,
    );
  }
}

extension $PaginatedStateCopyWith<TItem> on PaginatedState<TItem> {
  /// Returns a callable class that can be used as follows: `instanceOfPaginatedState.copyWith(...)` or like so:`instanceOfPaginatedState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaginatedStateCWProxy<TItem> get copyWith =>
      _$PaginatedStateCWProxyImpl<TItem>(this);
}
