import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/query_cubit.dart';

/// Signature for a function that creates a widget when data successfully loaded.
typedef QueryWidgetBuilder<TOut> = Widget Function(
  BuildContext context,
  TOut data,
);

/// Signature for a function that creates a widget when query is loading.
typedef QueryErrorBuilder<TOut> = Widget Function(
  BuildContext context,
  QueryErrorState<TOut> error,
);

/// A widget that builds itself based on the latest query state.
class QueryCubitBuilder<TRes, TOut> extends StatelessWidget {
  /// Creates a new [QueryCubitBuilder] with the given [queryCubit] and
  /// [builder].
  const QueryCubitBuilder({
    super.key,
    required this.queryCubit,
    required this.builder,
    this.onLoading,
    this.onError,
  });

  /// The query cubit to which this widget is listening.
  final BaseQueryCubit<TRes, TOut> queryCubit;

  /// The builder that creates a widget when data successfully loaded.
  final QueryWidgetBuilder<TOut> builder;

  /// The builder that creates a widget when query is loading.
  final WidgetBuilder? onLoading;

  /// The builder that creates a widget when query is failed.
  final QueryErrorBuilder<TOut>? onError;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BaseQueryCubit<TRes, TOut>>.value(
      value: queryCubit,
      child: BlocBuilder<BaseQueryCubit<TRes, TOut>, QueryState<TOut>>(
        builder: (context, state) {
          return switch (state) {
            QueryInitialState() ||
            QueryLoadingState() =>
              onLoading?.call(context) ??
                  const CircularProgressIndicator.adaptive(),
            QuerySuccessState(:final data) => builder(context, data),
            QueryErrorState() =>
              onError?.call(context, state) ?? const Text('ERROR!'),
          };
        },
      ),
    );
  }
}
