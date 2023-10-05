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

/// A builder for the error state widget in PaginatedCubitLayout.
typedef PaginatedErrorBuilder<TItem> = Widget Function(
  BuildContext context,
  VoidCallback? retry,
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
    this.firstPageLoadingBuilder,
    this.firstPageErrorBuilder,
    this.nextPageErrorBuilder,
    this.nextPageLoadingBuilder,
  });

  /// The cubit that handles the paginated data.
  final PaginatedCubit<TData, dynamic, TItem> cubit;

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

  /// An optional builder for the loading state of the first page.
  final WidgetBuilder? firstPageLoadingBuilder;

  /// An optional builder for the error state of the first page.
  final PaginatedErrorBuilder<dynamic>? firstPageErrorBuilder;

  /// An optional builder for the loading state of the next page.
  final WidgetBuilder? nextPageLoadingBuilder;

  /// An optional builder for the error state of the next page.
  final PaginatedErrorBuilder<dynamic>? nextPageErrorBuilder;

  @override
  Widget build(BuildContext context) {
    final config = context.read<PaginatedConfig>();

    return CustomScrollView(
      slivers: [
        if (headerBuilder != null) headerBuilder!(context),
        BlocBuilder<PaginatedCubit<TData, dynamic, TItem>,
            PaginatedState<TData, TItem>>(
          bloc: cubit,
          builder: (context, state) {
            return switch (state.type) {
              // TODO: Add separate builder for the initial state and the preRequestLoading state.
              PaginatedStateType.initial ||
              PaginatedStateType.preRequestLoading ||
              PaginatedStateType.firstPageLoading =>
                firstPageLoadingBuilder?.call(context) ??
                    config.onFirstPageLoading(context),
              // TODO: Add separate builder for the preRequestError state.
              PaginatedStateType.firstPageError ||
              PaginatedStateType.preRequestError =>
                _buildFirstPageError(
                  context,
                  state,
                ),
              PaginatedStateType.refresh when state.error != null =>
                _buildFirstPageError(
                  context,
                  state,
                ),
              _ => _PaginatedLayoutList(
                  state: state,
                  items: state.items,
                  itemBuilder: itemBuilder,
                  separatorBuilder: separatorBuilder,
                  fetchNextPage: () => cubit.fetchNextPage(
                    state.args.pageId + 1,
                  ),
                  nextPageError: _buildNextPageError(context, state),
                  nextPageLoading: _buildNextPageLoader(context, state),
                  emptyState: emptyStateBuilder?.call(context) ??
                      config.onEmptyState(context),
                ),
            };
          },
        ),
        if (footerBuilder != null) footerBuilder!(context),
      ],
    );
  }

  Widget _buildFirstPageError(
    BuildContext context,
    PaginatedState<TData, TItem> state,
  ) {
    final config = context.read<PaginatedConfig>();
    final callback = firstPageErrorBuilder ?? config.onFirstPageError;
    return callback(context, () => cubit.fetchNextPage(0));
  }

  Widget? _buildNextPageLoader(
    BuildContext context,
    PaginatedState<TData, TItem> state,
  ) {
    final config = context.read<PaginatedConfig>();
    if (state.type == PaginatedStateType.nextPageLoading) {
      final callback = nextPageLoadingBuilder ?? config.onNextPageLoading;
      return callback(context);
    }
    return null;
  }

  Widget? _buildNextPageError(
    BuildContext context,
    PaginatedState<TData, TItem> state,
  ) {
    final config = context.read<PaginatedConfig>();
    if (state.type == PaginatedStateType.nextPageError) {
      final callback = nextPageErrorBuilder ?? config.onNextPageError;
      return callback(
        context,
        () => cubit.fetchNextPage(state.args.pageId + 1),
      );
    }
    return null;
  }
}

class _PaginatedLayoutList<TData, TItem> extends HookWidget {
  const _PaginatedLayoutList({
    required this.state,
    required this.items,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.fetchNextPage,
    required this.emptyState,
    this.nextPageError,
    this.nextPageLoading,
    this.nextPageThreshold = 3,
  });

  final PaginatedState<TData, TItem> state;
  final List<TItem> items;
  final PaginatedItemBuilder<TData, TItem> itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;

  final VoidCallback fetchNextPage;
  final Widget emptyState;
  final Widget? nextPageLoading;
  final Widget? nextPageError;

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
          emptyState,
        if (nextPageLoading != null) nextPageLoading!,
        if (nextPageError != null) nextPageError!,
      ],
    );
  }

  Widget _itemBuilder(
    BuildContext context,
    int index,
  ) {
    final newPageRequestTriggerIndex = max(0, items.length - nextPageThreshold);

    final isBuildingTriggerIndexItem = index == newPageRequestTriggerIndex;

    if (state.hasNextPage &&
        isBuildingTriggerIndexItem &&
        !state.type.shouldNotGetNextPage) {
      fetchNextPage();
    }

    return itemBuilder(context, null, index, items);
  }
}
