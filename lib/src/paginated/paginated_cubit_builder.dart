import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

/// A widget that rebuilds when the state of a PaginatedCubit changes.
class PaginatedCubitBuilder<TData, TItem> extends StatelessWidget {
  /// Creates a new PaginatedCubitBuilder.
  const PaginatedCubitBuilder({
    super.key,
    required this.cubit,
    required this.builder,
  });

  /// The cubit that handles the paginated data.
  final PaginatedCubit<dynamic, TData, dynamic, TItem> cubit;

  /// A builder function that is invoked when the cubit emits a new state.
  final Widget Function(
    BuildContext context,
    PaginatedState<TData, TItem> state,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedCubit<dynamic, TData, dynamic, TItem>,
        PaginatedState<TData, TItem>>(
      bloc: cubit,
      builder: builder,
    );
  }
}
