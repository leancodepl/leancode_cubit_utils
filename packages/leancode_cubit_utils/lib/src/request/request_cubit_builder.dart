import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/request/request_config_provider.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';

/// Signature for a function that creates a widget when data successfully loaded.
typedef RequestWidgetBuilder<TOut> =
    Widget Function(BuildContext context, TOut? data);

/// Signature for a function that creates a widget when request is loading.
typedef RequestErrorBuilder<TError> =
    Widget Function(
      BuildContext context,
      RequestErrorState<dynamic, TError> error,
      VoidCallback retry,
    );

/// A widget that builds itself based on the latest request state.
class RequestCubitBuilder<TOut, TError> extends StatelessWidget {
  /// Creates a new [RequestCubitBuilder] with the given [cubit] and
  /// [onSuccess].
  const RequestCubitBuilder({
    super.key,
    required this.cubit,
    required this.onSuccess,
    this.onInitial,
    this.onLoading,
    this.onEmpty,
    this.onRefreshing,
    this.onError,
    this.onErrorCallback,
  });

  /// The request cubit to which this widget is listening.
  final BaseRequestCubit<dynamic, TOut, TError> cubit;

  /// The builder that creates a widget when data successfully loaded.
  final RequestWidgetBuilder<TOut> onSuccess;

  /// The builder that creates a widget when state is initial.
  final WidgetBuilder? onInitial;

  /// The builder that creates a widget when request is loading.
  final WidgetBuilder? onLoading;

  /// The builder that creates a widget when request returns empty data.
  final WidgetBuilder? onEmpty;

  /// The builder that creates a widget when request is refreshing.
  final RequestWidgetBuilder<TOut>? onRefreshing;

  /// The builder that creates a widget when request failed.
  final RequestErrorBuilder<TError>? onError;

  /// Callback to be called on error widget;
  final VoidCallback? onErrorCallback;

  @override
  Widget build(BuildContext context) {
    final config = context.read<RequestLayoutConfig>();

    final effectiveOnLoading = onLoading ?? config.onLoading;
    final effectiveInitial = onInitial ?? effectiveOnLoading;
    final effectiveOnEmpty = onEmpty ?? config.onEmpty;

    return BlocBuilder<
      BaseRequestCubit<dynamic, TOut, TError>,
      RequestState<TOut, TError>
    >(
      bloc: cubit,
      builder: (context, state) => state.map(
        onInitial: () => effectiveInitial(context),
        onLoading: () => effectiveOnLoading(context),
        onSuccess: (data) => onSuccess(context, data),
        onEmpty: effectiveOnEmpty != null
            ? (_) => effectiveOnEmpty(context)
            : null,
        onRefreshing: switch (onRefreshing) {
          final onRefreshing? => (data) => onRefreshing(context, data),
          null => null,
        },
        onError: (err, _, _) {
          final errorState = state as RequestErrorState<dynamic, TError>;
          final callback = onErrorCallback ?? cubit.refresh;

          return (onError ?? config.onError)(context, errorState, callback);
        },
      ),
    );
  }
}
