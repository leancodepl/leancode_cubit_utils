import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/query_cubit.dart';
import 'package:leancode_cubit_utils/src/query_provider.dart';

/// Signature for a function that creates a widget when data successfully loaded.
typedef QueryWidgetBuilder<TOut> = Widget Function(
  BuildContext context,
  TOut data,
);

/// Signature for a function that creates a widget when query is loading.
typedef QueryErrorBuilder<TOut> = Widget Function(
  BuildContext context,
  QueryErrorState<TOut> error,
  VoidCallback? retry,
);

/// A widget that builds itself based on the latest query state.
class QueryCubitBuilder<TOut> extends StatelessWidget {
  /// Creates a new [QueryCubitBuilder] with the given [queryCubit] and
  /// [builder].
  const QueryCubitBuilder({
    super.key,
    required this.queryCubit,
    required this.builder,
    this.onLoading,
    this.onError,
    this.onErrorCallback,
  });

  /// The query cubit to which this widget is listening.
  final BaseQueryCubit<dynamic, TOut> queryCubit;

  /// The builder that creates a widget when data successfully loaded.
  final QueryWidgetBuilder<TOut> builder;

  /// The builder that creates a widget when query is loading.
  final WidgetBuilder? onLoading;

  /// The builder that creates a widget when query is failed.
  final QueryErrorBuilder<TOut>? onError;

  /// Callback to be called on error widget;
  final VoidCallback? onErrorCallback;

  @override
  Widget build(BuildContext context) {
    final config = context.read<QueryConfig>();

    return BlocBuilder<BaseQueryCubit<dynamic, TOut>, QueryState<TOut>>(
      bloc: queryCubit,
      builder: (context, state) {
        return switch (state) {
          QueryInitialState() ||
          QueryLoadingState() =>
            onLoading?.call(context) ?? config.onLoading(context),
          QuerySuccessState(:final data) => builder(context, data),
          QueryRefreshState(:final data) => data != null
              ? builder(context, data)
              : onLoading?.call(context) ?? config.onLoading(context),
          QueryErrorState() => onError?.call(context, state, onErrorCallback) ??
              config.onError(context, state),
        };
      },
    );
  }
}
