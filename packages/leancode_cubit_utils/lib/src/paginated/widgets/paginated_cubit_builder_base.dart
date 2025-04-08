import 'package:flutter/widgets.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// A widget that rebuilds when the state of a PaginatedCubit changes.
abstract class PaginatedCubitBuilderBase<TData, TItem> extends StatelessWidget {
  /// Creates a new PaginatedCubitBuilderBase.
  const PaginatedCubitBuilderBase({
    super.key,
    required this.cubit,
    required this.builder,
  });

  /// The cubit that handles the paginated data.
  final PaginatedCubit<TData, dynamic, dynamic, TItem> cubit;

  /// A builder function that is invoked when the cubit emits a new state.
  final Widget Function(
    BuildContext context,
    PaginatedState<TData, TItem> state,
  ) builder;
}
