import 'package:flutter/widgets.dart';
import 'package:leancode_cubit_utils/src/paginated/widgets/paginated_cubit_builder.dart';
import 'package:leancode_cubit_utils/src/paginated/widgets/paginated_cubit_builder_base.dart';

/// A sliver that rebuilds when the state of a PaginatedCubit changes.
class SliverPaginatedCubitBuilder<TData, TItem>
    extends PaginatedCubitBuilderBase<TData, TItem> {
  /// Creates a new SliverPaginatedCubitBuilder.
  const SliverPaginatedCubitBuilder({
    super.key,
    required super.cubit,
    required super.builder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: PaginatedCubitBuilder(
        cubit: cubit,
        builder: builder,
      ),
    );
  }
}
