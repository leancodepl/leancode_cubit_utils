import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_cubit.dart';
import 'package:leancode_hooks/leancode_hooks.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'paginated_config_provider.dart';

/// A builder for a paginated list item.
typedef PaginatedItemBuilder<TData, TItem> = Widget Function(
  BuildContext context,
  TData? data,
  int index,
  List<TItem> items,
);

/// A layout for a paginated cubit.
class PaginatedCubitLayout<TData, TItem> extends StatelessWidget {
  /// Creates a PaginatedCubitLayout.
  const PaginatedCubitLayout({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.emptyStateBuilder,
    this.nextPageErrorBuilder,
    this.nextPageLoadingBuilder,
  });

  /// The cubit that handles the paginated data.
  final PaginatedCubit<dynamic, TItem> cubit;

  /// A builder for a paginated list item.
  final PaginatedItemBuilder<TData, TItem> itemBuilder;

  /// A builder for a separator between items.
  final IndexedWidgetBuilder separatorBuilder;

  /// An optional builder for the header.
  final WidgetBuilder? headerBuilder;

  /// An optional builder for the footer.
  final WidgetBuilder? footerBuilder;

  /// An optional builder for the empty state.
  final WidgetBuilder? emptyStateBuilder;

  /// An optional builder for the loading state of the next page.
  final WidgetBuilder? nextPageLoadingBuilder;

  /// An optional builder for the error state of the next page.
  final WidgetBuilder? nextPageErrorBuilder;

  @override
  Widget build(BuildContext context) {
    final config = context.read<PaginatedConfig>();
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: CustomScrollView(
        slivers: [
          if (headerBuilder != null) headerBuilder!(context),
          BlocBuilder<PaginatedCubit<dynamic, TItem>, PaginatedState<TItem>>(
            bloc: cubit,
            builder: (context, state) {
              return switch (state.type) {
                PaginatedStateType.initial ||
                PaginatedStateType.firstPageLoading =>
                  config.onFirstPageLoading(context),
                PaginatedStateType.firstPageError =>
                  config.onFirstPageError(context),
                _ => _PaginatedLayoutList(
                    items: state.items,
                    itemBuilder: itemBuilder,
                    separatorBuilder: separatorBuilder,
                    fetchNextPage: () => cubit.fetchNextPage(state.pageId + 1),
                    nextPageErrorBuilder:
                        state.type == PaginatedStateType.nextPageError
                            ? nextPageErrorBuilder ?? config.onNextPageError
                            : null,
                    nextPageLoadingBuilder:
                        state.type == PaginatedStateType.nextPageLoading
                            ? nextPageLoadingBuilder ?? config.onNextPageLoading
                            : null,
                    emptyStateBuilder: emptyStateBuilder ?? config.onEmptyState,
                    hasNextPage: state.hasNextPage,
                  ),
              };
            },
          ),
          if (footerBuilder != null) footerBuilder!(context),
        ],
      ),
    );
  }
}

class _PaginatedLayoutList<TData, TItem> extends HookWidget {
  const _PaginatedLayoutList({
    required this.items,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.fetchNextPage,
    required this.hasNextPage,
    required this.emptyStateBuilder,
    this.nextPageErrorBuilder,
    this.nextPageLoadingBuilder,
    this.nextPageThreshold = 3,
  });

  final List<TItem> items;
  final PaginatedItemBuilder<TData, TItem> itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;

  final VoidCallback fetchNextPage;
  final bool hasNextPage;
  final WidgetBuilder emptyStateBuilder;
  final WidgetBuilder? nextPageLoadingBuilder;
  final WidgetBuilder? nextPageErrorBuilder;

  /// The number of remaining items that should trigger a new fetch.
  final int nextPageThreshold;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        if (items.isNotEmpty)
          SliverList.separated(
            itemBuilder: _itemBuilder,
            separatorBuilder: separatorBuilder,
            itemCount: items.length,
          )
        else
          emptyStateBuilder.call(context),
        if (nextPageLoadingBuilder != null) nextPageLoadingBuilder!(context),
        if (nextPageErrorBuilder != null) nextPageErrorBuilder!(context),
      ],
    );
  }

  // TODO: Find a way to not trigger fetchNextPage multiple times.
  Widget _itemBuilder(
    BuildContext context,
    int index,
  ) {
    final newPageRequestTriggerIndex = max(0, items.length - nextPageThreshold);

    final isBuildingTriggerIndexItem = index == newPageRequestTriggerIndex;

    if (hasNextPage && isBuildingTriggerIndexItem) {
      fetchNextPage();
    }

    return itemBuilder(context, null, index, items);
  }
}
