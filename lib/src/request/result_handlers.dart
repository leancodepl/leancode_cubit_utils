import 'package:cqrs/cqrs.dart';
import 'package:leancode_cubit_utils/src/request/request_cubit.dart';
import 'package:logging/logging.dart';

/// Handles the given CQRS QueryResult and returns the corresponding state.
Future<RequestState<TOut, QueryError>> queryResultHandler<TData, TOut>(
  QueryResult<TData> result,
  Future<RequestErrorState<TOut, QueryError>> Function(
    RequestErrorState<TOut, QueryError> errorState,
  ) errorMapper,
  TOut Function(TData) dataMapper,
  Logger logger,
) async {
  if (result case QuerySuccess(:final data)) {
    logger.info('Query success. Data: $data');
    return RequestSuccessState(dataMapper(data));
  } else if (result case QueryFailure(:final error)) {
    logger.severe('Query error. Error: $error');
    try {
      return await errorMapper(RequestErrorState(error: error));
    } catch (e, s) {
      logger.severe(
        'Processing error failed. Exception: $e. Stack trace: $s',
      );
      return RequestErrorState(exception: e, stackTrace: s);
    }
  } else {
    return RequestErrorState();
  }
}
