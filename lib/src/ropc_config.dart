import 'package:simple_https_service/simple_https_service.dart';

/// (en) Singleton configuration for ROPCClient and ROPCClientForNative.
/// Use this to control retry behavior independently of the global RetryConfig
/// in simple_https_service.
///
/// (ja) ROPCClient および ROPCClientForNative 用のシングルトン設定クラスです。
/// simple_https_service のグローバル RetryConfig に依存せず、
/// JWTマネージャーのリトライ動作を独立して制御できます。
///
/// Author Masahide Mori
///
/// First edition creation date 2026-05-03 00:00:00
class ROPCConfig {
  static final ROPCConfig _instance = ROPCConfig._internal();

  factory ROPCConfig() => _instance;

  ROPCConfig._internal();

  /// Maximum number of retries on failure. Defaults to 0 (no retries).
  int maxRetries = 0;

  /// Base delay for exponential backoff.
  Duration baseDelay = const Duration(seconds: 1);

  /// Maximum random jitter added to each retry delay.
  Duration maxJitter = const Duration(milliseconds: 500);

  /// Condition under which a retry is attempted.
  /// If null, no retries occur (maxRetries is ignored).
  bool Function(String url, ServerResponse res, Object? error)? retryCondition;
}
