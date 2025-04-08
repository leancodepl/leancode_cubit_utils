import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
import 'package:leancode_cubit_utils/src/request/widgets/request_config_provider.dart';
import 'package:leancode_cubit_utils/src/request/widgets/request_cubit_builder_base.dart';

/// A widget that builds itself based on the latest request state.
class RequestCubitBuilder<TOut, TError>
    extends RequestCubitBuilderBase<TOut, TError> {
  /// Creates a new [RequestCubitBuilder] with the given [cubit] and
  /// [builder].
  const RequestCubitBuilder({
    super.key,
    required super.cubit,
    required super.builder,
    super.onInitial,
    super.onLoading,
    super.onEmpty,
    super.onError,
    super.onErrorCallback,
  });

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
          RequestEmptyState() => onEmpty?.call(context) ??
              config.onEmpty?.call(context) ??
              const SizedBox(),
          RequestErrorState() => onError?.call(
                context,
                state,
                onErrorCallback ?? cubit.refresh,
              ) ??
              config.onError(context, state, onErrorCallback ?? cubit.refresh),
        };
      },
    );
  }
}
