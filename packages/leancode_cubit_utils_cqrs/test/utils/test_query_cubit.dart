import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';
import 'package:leancode_cubit_utils_cqrs/leancode_cubit_utils_cqrs.dart';

import 'test_query.dart';

class TestQueryCubit extends QueryCubit<String, String> {
  TestQueryCubit(
    super.loggerTag, {
    super.requestMode,
    required this.cqrs,
    required this.id,
  });

  final Cqrs cqrs;
  final String id;

  @override
  String map(String data) {
    if (data == 'Mapping fails') {
      throw Exception('Mapping failed');
    }
    return 'Mapped $data';
  }

  @override
  Future<QueryResult<String>> request() {
    return cqrs.get(TestQuery(id: id));
  }

  @override
  Future<RequestErrorState<String, QueryError>> handleError(
    RequestErrorState<String, QueryError> errorState,
  ) async {
    if (errorState.error == QueryError.unknown) {
      throw Exception('onQueryError failed');
    } else {
      return errorState;
    }
  }
}

class TestArgsQueryCubit extends ArgsQueryCubit<String, String, String> {
  TestArgsQueryCubit(
    super.loggerTag, {
    required this.cqrs,
  });

  final Cqrs cqrs;

  @override
  String map(String data) => data;

  @override
  Future<QueryResult<String>> request(String args) {
    return cqrs.get(TestQuery(id: args));
  }
}
