import 'package:flutter_test/flutter_test.dart';
import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';

void main() {
  group('ROPCConfig', () {
    setUp(() {
      ROPCConfig().maxRetries = 0;
      ROPCConfig().baseDelay = const Duration(seconds: 1);
      ROPCConfig().maxJitter = const Duration(milliseconds: 500);
      ROPCConfig().retryCondition = null;
    });

    test('is singleton', () {
      final a = ROPCConfig();
      final b = ROPCConfig();
      expect(identical(a, b), isTrue);
    });

    test('defaults to no retries', () {
      expect(ROPCConfig().maxRetries, 0);
    });

    test('default baseDelay is 1 second', () {
      expect(ROPCConfig().baseDelay, const Duration(seconds: 1));
    });

    test('default maxJitter is 500 milliseconds', () {
      expect(ROPCConfig().maxJitter, const Duration(milliseconds: 500));
    });

    test('default retryCondition is null', () {
      expect(ROPCConfig().retryCondition, isNull);
    });

    test('can update maxRetries', () {
      ROPCConfig().maxRetries = 3;
      expect(ROPCConfig().maxRetries, 3);
    });

    test('can set retryCondition', () {
      bool called = false;
      ROPCConfig().retryCondition = (url, res, error) {
        called = true;
        return false;
      };
      ROPCConfig().retryCondition!(
          'https://example.com',
          ServerResponse(null, EnumServerResponseStatus.otherError, null, null),
          null);
      expect(called, isTrue);
    });
  });
}
