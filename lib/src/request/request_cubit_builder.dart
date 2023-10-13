import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/request/request_config_provider.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';

/// Signature for a function that creates a widget when data successfully loaded.
typedef RequestWidgetBuilder<TOut> = Widget Function(
  BuildContext context,
  TOut data,
);

/// Signature for a function that creates a widget when request is loading.
typedef RequestErrorBuilder<TError> = Widget Function(
  BuildContext context,
  RequestErrorState<dynamic, TError> error,
  VoidCallback? retry,
);

/// A widget that builds itself based on the latest request state.
class RequestCubitBuilder<TOut, TError> extends StatelessWidget {
  /// Creates a new [RequestCubitBuilder] with the given [cubit] and
  /// [builder].
  const RequestCubitBuilder({
    super.key,
    required this.cubit,
    required this.builder,
    this.onInitial,
    this.onLoading,
    this.onError,
    this.onErrorCallback,
  });

  /// The request cubit to which this widget is listening.
  final BaseRequestCubit<dynamic, dynamic, TOut, TError> cubit;

  /// The builder that creates a widget when data successfully loaded.
  final RequestWidgetBuilder<TOut> builder;

  /// The builder that creates a widget when state is initial.
  final WidgetBuilder? onInitial;

  /// The builder that creates a widget when request is loading.
  final WidgetBuilder? onLoading;

  /// The builder that creates a widget when request failed.
  final RequestErrorBuilder<TError>? onError;

  /// Callback to be called on error widget;
  final VoidCallback? onErrorCallback;

  @override
  Widget build(BuildContext context) {
    final config = context.read<RequestLayoutConfig>();

    return BlocBuilder<BaseRequestCubit<dynamic, dynamic, TOut, TError>,
        RequestState<TOut, TError>>(
      bloc: cubit,
      builder: (context, state) {
        return switch (state) {
          RequestInitialState() => onInitial?.call(context) ??
              onLoading?.call(context) ??
              config.onLoading(context),
          RequestLoadingState() =>
            onLoading?.call(context) ?? config.onLoading(context),
          RequestSuccessState(:final data) => builder(context, data),
          RequestRefreshState(:final data) => data != null
              ? builder(context, data)
              : onLoading?.call(context) ?? config.onLoading(context),
          RequestErrorState() =>
            onError?.call(context, state, onErrorCallback) ??
                config.onError(context, state, onErrorCallback),
        };
      },
    );
  }
}
