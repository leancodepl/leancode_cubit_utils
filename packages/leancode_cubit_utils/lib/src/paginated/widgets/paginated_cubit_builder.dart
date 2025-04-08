import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils/src/paginated/widgets/paginated_cubit_builder_base.dart';

/// A widget that rebuilds when the state of a PaginatedCubit changes.
class PaginatedCubitBuilder<TData, TItem>
    extends PaginatedCubitBuilderBase<TData, TItem> {
  /// Creates a new PaginatedCubitBuilder.
  const PaginatedCubitBuilder({
    super.key,
    required super.cubit,
    required super.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedCubit<TData, dynamic, dynamic, TItem>,
        PaginatedState<TData, TItem>>(
      bloc: cubit,
      builder: builder,
    );
  }
}
