import 'package:flutter/material.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:provider/provider.dart';

/// A configuration for PaginatedCubitLayout.
class PaginatedLayoutConfig {
  /// Creates a PaginatedLayoutConfig.
  const PaginatedLayoutConfig({
    required this.onNextPageLoading,
    required this.onNextPageError,
    required this.onFirstPageLoading,
    required this.onFirstPageError,
    required this.onEmptyState,
  });

  /// A builder for the loading state of the next page.
  final WidgetBuilder onNextPageLoading;

  /// A builder for the error state of the next page.
  final PaginatedErrorBuilder<dynamic> onNextPageError;

  /// A builder for the loading state of the first page.
  final WidgetBuilder onFirstPageLoading;

  /// A builder for the error state of the first page.
  final PaginatedErrorBuilder<dynamic> onFirstPageError;

  /// A builder for the empty state.
  final WidgetBuilder onEmptyState;
}

/// A provider for default configuration for PaginatedLayoutConfigProvider.
class PaginatedLayoutConfigProvider extends StatelessWidget {
  /// Creates a PaginatedLayoutConfigProvider.
  const PaginatedLayoutConfigProvider({
    super.key,
    this.runDebounce,
    this.pageSize,
    this.searchBeginAt,
    this.firstPageIndex,
    required this.onNextPageLoading,
    required this.onNextPageError,
    required this.onFirstPageLoading,
    required this.onFirstPageError,
    required this.onEmptyState,
    required this.child,
  });

  /// The default duration for run in PaginatedCubit when withDebounce is used.
  final Duration? runDebounce;

  /// The default page size used by all PaginatedCubits.
  final int? pageSize;

  /// The number of characters after which the search query will be sent.
  final int? searchBeginAt;

  /// The first page index.
  final int? firstPageIndex;

  /// A builder for the loading state of the next page.
  final WidgetBuilder onNextPageLoading;

  /// A builder for the error state of the next page.
  final PaginatedErrorBuilder<dynamic> onNextPageError;

  /// A builder for the loading state of the first page.
  final WidgetBuilder onFirstPageLoading;

  /// A builder for the error state of the first page.
  final PaginatedErrorBuilder<dynamic> onFirstPageError;

  /// A builder for the empty state.
  final WidgetBuilder onEmptyState;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    PaginatedConfigProvider.config = PaginatedConfigProvider.config.copyWith(
      pageSize: pageSize,
      runDebounce: runDebounce,
      searchBeginAt: searchBeginAt,
      firstPageIndex: firstPageIndex,
    );

    return Provider(
      create: (context) => PaginatedLayoutConfig(
        onNextPageLoading: onNextPageLoading,
        onNextPageError: onNextPageError,
        onFirstPageLoading: onFirstPageLoading,
        onFirstPageError: onFirstPageError,
        onEmptyState: onEmptyState,
      ),
      child: child,
    );
  }
}
