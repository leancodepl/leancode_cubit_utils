import 'package:leancode_cubit_utils/src/request/request_cubit.dart';

/// Configures the [RequestCubit]s.
class RequestCubitConfig {
  /// The default request mode used by all [RequestCubit]s.
  static RequestMode get requestMode => _requestMode ?? RequestMode.ignore;

  static set requestMode(RequestMode mode) => _requestMode = mode;

  static RequestMode? _requestMode;
}
