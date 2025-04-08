import 'package:flutter/widgets.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit_config.dart';
import 'package:leancode_cubit_utils/src/request/widgets/request_cubit_builder.dart';
import 'package:leancode_cubit_utils/src/request/widgets/request_cubit_builder_base.dart';
import 'package:provider/provider.dart';

/// A default root config.
class RequestLayoutConfig {
  /// Creates a new [RequestLayoutConfig].
  RequestLayoutConfig({
    required this.onLoading,
    required this.onEmpty,
    required this.onError,
  });

  /// The builder that creates a widget when request is loading.
  final WidgetBuilder onLoading;

  /// The builder that creates a widget when request returns empty data.
  final WidgetBuilder? onEmpty;

  /// The builder that creates a widget when request failed.
  final RequestErrorBuilder<dynamic> onError;
}

/// A widget that provides default loading and error widgets for [RequestCubitBuilder].
class RequestLayoutConfigProvider extends StatelessWidget {
  /// Creates a new [RequestLayoutConfigProvider].
  const RequestLayoutConfigProvider({
    super.key,
    this.requestMode,
    required this.onLoading,
    required this.onError,
    required this.child,
    this.onEmpty,
  });

  /// The default request mode used by all [RequestCubit]s.
  final RequestMode? requestMode;

  /// The builder that creates a widget when request is loading.
  final WidgetBuilder onLoading;

  /// The builder that creates a widget when request returns empty data.
  final WidgetBuilder? onEmpty;

  /// The builder that creates a widget when request failed.
  final RequestErrorBuilder<dynamic> onError;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Sets the default request mode.
    if (requestMode != null) {
      RequestCubitConfig.requestMode = requestMode!;
    }

    return Provider(
      create: (context) => RequestLayoutConfig(
        onLoading: onLoading,
        onEmpty: onEmpty,
        onError: onError,
      ),
      child: child,
    );
  }
}
