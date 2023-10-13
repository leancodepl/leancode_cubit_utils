import 'package:flutter/widgets.dart';
import 'package:leancode_cubit_utils/src/query/query_cubit.dart';
import 'package:leancode_cubit_utils/src/query/query_cubit_builder.dart';
import 'package:leancode_cubit_utils/src/query/query_cubit_config.dart';
import 'package:provider/provider.dart';

/// A default root config.
class QueryConfig {
  /// Creates a new [QueryConfig].
  QueryConfig({
    required this.onLoading,
    required this.onError,
  });

  /// The builder that creates a widget when query is loading.
  final WidgetBuilder onLoading;

  /// The builder that creates a widget when query failed.
  final QueryErrorBuilder<dynamic> onError;
}

/// A widget that provides default loading and error widgets for [QueryCubitBuilder].
class QueryConfigProvider extends StatelessWidget {
  /// Creates a new [QueryConfigProvider].
  const QueryConfigProvider({
    super.key,
    this.requestMode,
    required this.onLoading,
    required this.onError,
    required this.child,
  });

  /// The default request mode used by all [QueryCubit]s.
  final RequestMode? requestMode;

  /// The builder that creates a widget when query is loading.
  final WidgetBuilder onLoading;

  /// The builder that creates a widget when query failed.
  final QueryErrorBuilder<dynamic> onError;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Sets the default request mode.
    if (requestMode != null) {
      QueryCubitConfig.requestMode = requestMode!;
    }

    return Provider(
      create: (context) => QueryConfig(
        onLoading: onLoading,
        onError: onError,
      ),
      child: child,
    );
  }
}
