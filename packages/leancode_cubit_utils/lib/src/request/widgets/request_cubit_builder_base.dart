import 'package:flutter/material.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// Signature for a function that creates a widget when data successfully loaded.
typedef RequestWidgetBuilder<TOut> = Widget Function(
  BuildContext context,
  TOut data,
);

/// Signature for a function that creates a widget when request is loading.
typedef RequestErrorBuilder<TError> = Widget Function(
  BuildContext context,
  RequestErrorState<dynamic, TError> error,
  VoidCallback retry,
);

/// A widget that builds itself based on the latest request state.
abstract class RequestCubitBuilderBase<TOut, TError> extends StatelessWidget {
  /// Creates a new [RequestCubitBuilderBase] with the given [cubit] and
  /// [builder].
  const RequestCubitBuilderBase({
    super.key,
    required this.cubit,
    required this.builder,
    this.onInitial,
    this.onLoading,
    this.onEmpty,
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

  /// The builder that creates a widget when request returns empty data.
  final WidgetBuilder? onEmpty;

  /// The builder that creates a widget when request failed.
  final RequestErrorBuilder<TError>? onError;

  /// Callback to be called on error widget;
  final VoidCallback? onErrorCallback;
}
