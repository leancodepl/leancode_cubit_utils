import 'package:flutter/material.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
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
    required this.onNextPageLoading,
    required this.onNextPageError,
    required this.onFirstPageLoading,
    required this.onFirstPageError,
    required this.onEmptyState,
    required this.child,
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

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
