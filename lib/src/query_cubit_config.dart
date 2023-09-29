import 'package:leancode_cubit_utils/src/query_cubit.dart';

/// Configures the [QueryCubit]s.
class QueryCubitConfig {
  /// The default request mode used by all [QueryCubit]s.
  static RequestMode get requestMode => _requestMode ?? RequestMode.replace;

  static set requestMode(RequestMode mode) => _requestMode = mode;

  static RequestMode? _requestMode;
}
