import 'package:flutter/material.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils/src/paginated/paginated_cubit_config.dart';
import 'package:provider/provider.dart';

/// A configuration for PaginatedCubitLayout.
class PaginatedConfig {
  /// Creates a PaginatedConfig.
  const PaginatedConfig({
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

/// A provider for default configuration for PaginatedCubitLayout.
class PaginatedConfigProvider extends StatelessWidget {
  /// Creates a PaginatedConfigProvider.
  const PaginatedConfigProvider({
    super.key,
    this.runDebounce,
    this.pageSize,
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
    // Sets the default page mode.
    if (pageSize != null) {
      PaginatedCubitConfig.pageSize = pageSize!;
    }
    // Sets the default duration for run in PaginatedCubit when withDebounce is used.
    if (runDebounce != null) {
      PaginatedCubitConfig.runDebounce = runDebounce!;
    }

    return Provider(
      create: (context) => PaginatedConfig(
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
