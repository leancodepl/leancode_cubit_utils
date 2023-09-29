import 'package:cqrs/cqrs.dart';
import 'package:flutter/widgets.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils/src/query_cubit_config.dart';
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
  final Widget Function(
    BuildContext context,
    QueryErrorState<dynamic> error,
  ) onError;
}

/// A widget that provides default loading and error widgets for [QueryCubitBuilder].
class QueryConfigProvider extends StatelessWidget {
  /// Creates a new [QueryConfigProvider].
  const QueryConfigProvider({
    super.key,
    required this.cqrs,
    required this.requestMode,
    required this.onLoading,
    required this.onError,
    required this.child,
  });

  /// The CQRS instance.
  final Cqrs cqrs;

  /// The default request mode used by all [QueryCubit]s.
  final RequestMode requestMode;

  /// The builder that creates a widget when query is loading.
  final WidgetBuilder onLoading;

  /// The builder that creates a widget when query failed.
  final Widget Function(
    BuildContext context,
    QueryErrorState<dynamic> error,
  ) onError;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Sets the default request mode.
    QueryCubitConfig.requestMode = requestMode;

    return Provider<Cqrs>.value(
      value: cqrs,
      child: Provider(
        create: (context) => QueryConfig(
          onLoading: onLoading,
          onError: onError,
        ),
        child: child,
      ),
    );
  }
}
