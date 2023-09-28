import 'package:cqrs/cqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/query_cubit.dart';

class QueryCubitBuilder<TRes, TOut> extends StatelessWidget {
  const QueryCubitBuilder({
    super.key,
    required this.queryCubit,
    required this.builder,
    this.onLoading,
    this.onError,
  });

  final BaseQueryCubit<TRes, TOut> queryCubit;
  final Widget Function(BuildContext context, TOut data) builder;
  final WidgetBuilder? onLoading;
  final Widget Function(BuildContext context, QueryError error)? onError;

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
            QueryErrorState(:final error) =>
              onError?.call(context, error) ?? const Text('ERROR!'),
          };
        },
      ),
    );
  }
}
