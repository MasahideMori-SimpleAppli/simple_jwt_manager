import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';

/// (en) An error reporting class for native devices.
/// This supports the use of self-signed certificates.
///
/// (ja) ネイティブデバイス用の、エラー報告のためのクラスです。
/// こちらは自己署名証明書の利用をサポートしています。
///
/// Author Masahide Mori
///
/// First edition creation date 2025-05-04 18:29:14
class ErrorReporterForNative {
  static final ErrorReporterForNative _instance =
      ErrorReporterForNative._internal();

  factory ErrorReporterForNative() => _instance;

  ErrorReporterForNative._internal();

  late String _endpointUrl;
  late String _appVersion;
  Map<String, dynamic>? _extraInfo;

  Duration _rateLimitWindow = Duration(seconds: 60);
  int _maxReportsPerWindow = 3;

  Future<void> Function(Map<String, dynamic> report)? _onSendFailure;

  final List<DateTime> _sendTimestamps = [];

  bool _avoidDuplicate = true;
  final Set<String> _sentErrorHashes = {};

  // Flag to allow reporting.
  bool allowReporting = true;

  /// (en)　Initialize this class. Run this after calling
  /// WidgetsFlutterBinding.ensureInitialized(); in main.dart.
  /// Also, in debug builds only, detailed information will be displayed in
  /// debugPrint when limits are exceeded or a transmission error occurs.
  ///
  /// (ja) このクラスを初期化します。main.dartで
  /// WidgetsFlutterBinding.ensureInitialized();を呼び出した後に実行してください。
  /// また、デバッグビルドでのみ、
  /// 制限超過や送信エラー時にはdebugPrintで詳細が出るようになっています。
  /// allowReportingがfalseの場合はエラーはpostされず、onSendFailureも起動しません。
  ///
  /// * [endpointUrl] : The endpoint to which error information is sent.
  /// The information sent is JSON and includes the ErrorReportObj params.
  /// * [appVersion] : Frontend app version information.
  /// * [rateLimitWindow] : A unit of time for limiting the amount of
  /// error reporting. The default value is Duration(seconds: 60).
  /// * [maxReportsPerWindow] : Specifies how many times an error report can be
  /// sent within a unit time. The default value is 3.
  /// * [extraInfo] : Additional information common to this app that is added
  /// during initialization, such as the app's platform information.
  /// * [onSendFailure] : A callback if the error report fails. For example,
  /// you can add an action to save the reportData to storage.
  /// * [getJWT] : If you need authenticated error reporting,
  /// you can add a function to get the token.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls that is
  /// automatically adjusted if adjustTiming is True.
  /// If consecutive calls are made earlier than this,
  /// they will wait until this interval before being executed.
  /// The unit is milliseconds.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded
  /// return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the
  /// format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the
  /// format { "r" : UTF-8 text }.
  /// * [charset] : Use this when you want to explicitly specify the charset in
  /// the HTTP header. If null, it will automatically be set to utf-8. Also,
  /// if you enter an empty string, no specification will be made.
  /// * [avoidDuplicate] : If true, prevent sending the same error multiple
  /// times. The default value is true.
  /// * [flutterErrorOnError] : You can set this if you want to integrate other
  /// error handling of FlutterError.onError.
  /// if so, the function will be executed before the error report is sent.
  /// * [platformDispatcherOnError] : You can set this if you integrate some
  /// other error handling, in which case a function will be executed after
  /// the error report is sent and the return value of the provided function
  /// will be used as the return value of PlatformDispatcher.instance.onError.
  void init({
    required String endpointUrl,
    required String appVersion,
    Duration? rateLimitWindow,
    int? maxReportsPerWindow,
    bool useDebugPrint = true,
    Map<String, dynamic>? extraInfo,
    Future<void> Function(Map<String, dynamic> reportData)? onSendFailure,
    Future<String> Function()? getJWT,
    bool Function(X509Certificate cert, String host, int port)?
        badCertificateCallback,
    Duration connectionTimeout = const Duration(seconds: 30),
    Duration responseTimeout = const Duration(seconds: 60),
    bool adjustTiming = true,
    int intervalMs = 1200,
    EnumServerResponseType resType = EnumServerResponseType.json,
    String? charset,
    bool avoidDuplicate = true,
    void Function(FlutterErrorDetails)? flutterErrorOnError,
    bool Function(Object, StackTrace)? platformDispatcherOnError,
  }) {
    _endpointUrl = endpointUrl;
    _appVersion = appVersion;
    _rateLimitWindow = rateLimitWindow ?? Duration(seconds: 60);
    _maxReportsPerWindow = maxReportsPerWindow ?? 3;
    _extraInfo = extraInfo;
    _onSendFailure = onSendFailure;

    // エラーの重複排除関係の設定
    _sentErrorHashes.clear();
    _avoidDuplicate = avoidDuplicate;

    // 内部で起こったエラーを自動でキャッチして送信する設定。
    final void Function(FlutterErrorDetails)? originalFlutterOnError =
        FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (flutterErrorOnError != null) {
        flutterErrorOnError(details);
      } else {
        if (originalFlutterOnError != null) {
          originalFlutterOnError(details);
        }
      }
      reportError(details.exception, details.stack,
          getJWT: getJWT,
          badCertificateCallback: badCertificateCallback,
          connectionTimeout: connectionTimeout,
          responseTimeout: responseTimeout,
          adjustTiming: adjustTiming,
          intervalMs: intervalMs,
          resType: resType,
          charset: charset);
    };
    final bool Function(Object, StackTrace)? originalPlatformOnError =
        PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(error, stack,
          getJWT: getJWT,
          badCertificateCallback: badCertificateCallback,
          connectionTimeout: connectionTimeout,
          responseTimeout: responseTimeout,
          adjustTiming: adjustTiming,
          intervalMs: intervalMs,
          resType: resType,
          charset: charset);
      if (platformDispatcherOnError != null) {
        return platformDispatcherOnError(error, stack);
      } else {
        if (originalPlatformOnError != null) {
          return originalPlatformOnError(error, stack);
        } else {
          return true;
        }
      }
    };
  }

  /// (en) Sends the error content to the backend.
  /// This method can be used alone after init.
  /// If allowReporting is false, no errors will be posted and
  /// onSendFailure will not fire.
  /// This method never throws an error.
  /// If an error occurs, it will be debugPrinted only in debug builds.
  ///
  /// (ja) エラー内容をバックエンドに送信します。
  /// このメソッドはinit後であれば単体でも利用できます。
  /// allowReportingがfalseの場合はエラーはpostされず、onSendFailureも起動しません。
  /// このメソッドはいかなる場合もエラーをスローしません。
  /// エラーが発生した場合、デバッグビルドの場合のみエラーがdebugPrintされます。
  ///
  /// * [error] : Error object. Must be able to convert to an appropriate
  /// message using toString.
  /// * [stackTrace] : Stack trace when an error occurred.
  /// If null is specified, the null will be sent.
  /// * [customExtraInfo] : When reporting an individual error,
  /// additional information, such as the location of the error, is added.
  /// The all values must be stringifiable.
  /// * [getJWT] : If you need authenticated error reporting,
  /// you can add a function to get the token.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls that is
  /// automatically adjusted if adjustTiming is True.
  /// If consecutive calls are made earlier than this,
  /// they will wait until this interval before being executed.
  /// The unit is milliseconds.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded
  /// return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the
  /// format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the
  /// format { "r" : UTF-8 text }.
  /// * [charset] : Use this when you want to explicitly specify the charset in
  /// the HTTP header. If null, it will automatically be set to utf-8. Also,
  /// if you enter an empty string, no specification will be made.
  Future<void> reportError(Object error, StackTrace? stackTrace,
      {Map<String, dynamic>? customExtraInfo,
      Future<String> Function()? getJWT,
      bool Function(X509Certificate cert, String host, int port)?
          badCertificateCallback,
      Duration connectionTimeout = const Duration(seconds: 30),
      Duration responseTimeout = const Duration(seconds: 60),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      String? charset}) async {
    try {
      if (!allowReporting) {
        return;
      }

      // エラーレポートが無限ループなどにならないように、
      // 指定時間中の送信上限を超えたら無視する設定。
      final now = DateTime.now();
      _sendTimestamps.removeWhere((t) => now.difference(t) > _rateLimitWindow);
      if (_sendTimestamps.length >= _maxReportsPerWindow) {
        if (kDebugMode) {
          debugPrint('[ErrorReporter] Rate limit exceeded. Error suppressed.');
        }
        return;
      }
      // これはここで追加して後続の連続処理も防ぐ必要がある。
      _sendTimestamps.add(now);

      // 重複エラーのチェック。customExtraInfoを含めたエラー識別用ハッシュの計算
      String? errorHash;
      if (_avoidDuplicate) {
        final List<String>? customInfoString = customExtraInfo?.entries
            .map((e) => '${e.key}:${e.value}')
            .toList()
          ?..sort();
        final String customInfoJoined = customInfoString?.join(',') ?? '';
        errorHash =
            '${error.toString()}|${stackTrace?.toString() ?? ''}|$customInfoJoined';
        if (_sentErrorHashes.contains(errorHash)) {
          if (kDebugMode) {
            debugPrint('[ErrorReporter] Duplicate error suppressed.');
          }
          return;
        }
      }

      // JWTが必要な場合は取得。
      String? jwt;
      if (getJWT != null) {
        jwt = await getJWT();
      }

      // 送信データを設定。
      final Map<String, dynamic> reportData = ErrorReportObj(
              _appVersion,
              error.toString(),
              stackTrace?.toString(),
              now.toIso8601String(),
              _extraInfo,
              customExtraInfo)
          .toDict();

      // バックエンドに送信。
      try {
        final response = await UtilHttpsForNative.post(
            _endpointUrl, reportData, EnumPostEncodeType.json,
            jwt: jwt,
            badCertificateCallback: badCertificateCallback,
            connectionTimeout: connectionTimeout,
            responseTimeout: responseTimeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs,
            resType: resType,
            charset: charset);
        if (response.resultStatus != EnumServerResponseStatus.success) {
          throw Exception('Server responded with ${response.resBody}');
        }
        // 送信に成功した場合のみ送信済みハッシュに登録。
        if (_avoidDuplicate && errorHash != null) {
          _sentErrorHashes.add(errorHash);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ErrorReporter] Error report failed: $e');
        }
        if (_onSendFailure != null) {
          await _onSendFailure!(reportData);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[ErrorReporter] Error reporting failed. The problem occurred before the report could be assembled.: $e');
      }
    }
  }
}
