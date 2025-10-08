import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

void main() {
  final defaultArgs = PaginatedArgs.fromConfig(PaginatedConfigProvider.config);

  group('should not throw error ', () {
    test('when TData type is void', () {
      expect(
        () => PaginatedState<void, String>(args: defaultArgs),
        returnsNormally,
      );
    });

    test('when TData is set to nullable', () {
      expect(
        () => PaginatedState<String?, String>(args: defaultArgs),
        returnsNormally,
      );
    });

    test('when TData is non-nullable but initial value is passed', () {
      expect(
        () =>
            PaginatedState<String, String>(args: defaultArgs, data: 'initial'),
        returnsNormally,
      );
    });
  });

  group('should throw error', () {
    test('when non-nullable type is set but no initial value is passed', () {
      expect(
        () => PaginatedState<String, String>(args: defaultArgs),
        throwsAssertionError,
      );
    });
  });
}
