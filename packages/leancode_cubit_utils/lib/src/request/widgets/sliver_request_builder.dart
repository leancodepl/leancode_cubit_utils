import 'package:flutter/cupertino.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils/src/request/widgets/request_cubit_builder_base.dart';

/// A sliver that builds itself based on the latest request state.
class SliverRequestCubitBuilder<TOut, TError>
    extends RequestCubitBuilderBase<TOut, TError> {
  /// Creates a new [SliverRequestCubitBuilder] with the given [cubit] and
  /// [builder].
  const SliverRequestCubitBuilder({
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
    return SliverToBoxAdapter(
      child: RequestCubitBuilder(
        cubit: cubit,
        builder: builder,
        onInitial: onInitial,
        onLoading: onLoading,
        onEmpty: onEmpty,
        onError: onError,
        onErrorCallback: onErrorCallback,
      ),
    );
  }
}
