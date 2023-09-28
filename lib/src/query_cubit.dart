import 'package:cqrs/cqrs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BaseQueryCubit<TRes, TOut> extends Cubit<QueryState<TOut>> {
  BaseQueryCubit() : super(QueryInitialState());

  Future<void> _get(Future<QueryResult<TRes>> Function() callback) async {
    emit(QueryLoadingState());

    final result = await callback();

    if (result case QuerySuccess(:final data)) {
      emit(QuerySuccessState(map(data)));
    } else if (result case QueryFailure(:final error)) {
      emit(onQueryError(error));
    }
  }

  TOut map(TRes data);

  QueryState<TOut> onQueryError(QueryError error) {
    return QueryErrorState(error);
  }
}

abstract class QueryCubit<TRes, TOut> extends BaseQueryCubit<TRes, TOut> {
  QueryCubit();

  Future<void> get() => _get(request);

  Future<QueryResult<TRes>> request();
}

abstract class ArgsQueryCubit<TArgs, TRes, TOut>
    extends BaseQueryCubit<TRes, TOut> {
  ArgsQueryCubit();

  Future<void> get(TArgs args) => _get(() => request(args));

  Future<QueryResult<TRes>> request(TArgs args);
}

sealed class QueryState<TOut> with EquatableMixin {}

final class QueryInitialState<TOut> extends QueryState<TOut> {
  @override
  List<Object?> get props => [];
}

final class QueryLoadingState<TOut> extends QueryState<TOut> {
  @override
  List<Object?> get props => [];
}

final class QuerySuccessState<TOut> extends QueryState<TOut> {
  QuerySuccessState(this.data);

  final TOut data;

  @override
  List<Object?> get props => [data];
}

final class QueryErrorState<TOut> extends QueryState<TOut> {
  QueryErrorState(this.error);

  final QueryError error;

  @override
  List<Object?> get props => [error];
}
