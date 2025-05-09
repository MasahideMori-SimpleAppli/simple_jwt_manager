import 'package:flutter/foundation.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';

/// (en) A general purpose error reporting class.
///
/// (ja) 汎用的な、エラー報告のためのクラスです。
///
/// Author Masahide Mori
///
/// First edition creation date 2025-05-04 18:27:47
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();

  factory ErrorReporter() => _instance;

  ErrorReporter._internal();

  late String _endpointUrl;
  late String _appVersion;
  Map<String, dynamic>? _extraInfo;

  Duration _rateLimitWindow = Duration(seconds: 60);
  int _maxReportsPerWindow = 3;

  Future<void> Function(Map<String, dynamic> report)? _onSendFailure;

  final List<DateTime> _sendTimestamps = [];

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
  /// * [timeout] : The response timeout.
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
  void init(
      {required String endpointUrl,
      required String appVersion,
      Duration? rateLimitWindow,
      int? maxReportsPerWindow,
      bool useDebugPrint = true,
      Map<String, dynamic>? extraInfo,
      Future<void> Function(Map<String, dynamic> reportData)? onSendFailure,
      Future<String> Function()? getJWT,
      Duration timeout = const Duration(seconds: 30),
      bool adjustTiming = true,
      intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      String? charset}) {
    _endpointUrl = endpointUrl;
    _appVersion = appVersion;
    _rateLimitWindow = rateLimitWindow ?? Duration(seconds: 60);
    _maxReportsPerWindow = maxReportsPerWindow ?? 3;
    _extraInfo = extraInfo;
    _onSendFailure = onSendFailure;

    // 内部で起こったエラーを自動でキャッチして送信する設定。
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportError(details.exception, details.stack,
          getJWT: getJWT,
          timeout: timeout,
          adjustTiming: adjustTiming,
          intervalMs: intervalMs,
          resType: resType,
          charset: charset);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(error, stack,
          getJWT: getJWT,
          timeout: timeout,
          adjustTiming: adjustTiming,
          intervalMs: intervalMs,
          resType: resType,
          charset: charset);
      return true;
    };
  }

  /// (en) Sends the error content to the backend.
  /// This method can be used alone after init.
  /// If allowReporting is false, no errors will be posted and
  /// onSendFailure will not fire.
  ///
  /// (ja) エラー内容をバックエンドに送信します。
  /// このメソッドはinit後であれば単体でも利用できます。
  /// allowReportingがfalseの場合はエラーはpostされず、onSendFailureも起動しません。
  ///
  /// * [error] : Error object. Must be able to convert to an appropriate
  /// message using toString.
  /// * [stackTrace] : Stack trace when an error occurred.
  /// If null is specified, the null will be sent.
  /// * [customExtraInfo] : When reporting an individual error,
  /// additional information, such as the location of the error, is added.
  /// * [getJWT] : If you need authenticated error reporting,
  /// you can add a function to get the token.
  /// * [timeout] : The response timeout.
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
      Duration timeout = const Duration(seconds: 30),
      bool adjustTiming = true,
      intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      String? charset}) async {
    if (!allowReporting) {
      return;
    }

    final now = DateTime.now();

    // JWTが必要な場合は取得。
    String? jwt;
    if (getJWT != null) {
      jwt = await getJWT();
    }

    // エラーレポートが無限ループなどにならないように、
    // 指定時間中の送信上限を超えたら無視する設定。
    _sendTimestamps.removeWhere((t) => now.difference(t) > _rateLimitWindow);
    if (_sendTimestamps.length >= _maxReportsPerWindow) {
      if (kDebugMode) {
        debugPrint('[ErrorReporter] Rate limit exceeded. Error suppressed.');
      }
      return;
    }
    _sendTimestamps.add(now);

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
      final response = await UtilHttps.post(
          _endpointUrl, reportData, EnumPostEncodeType.json,
          jwt: jwt,
          timeout: timeout,
          adjustTiming: adjustTiming,
          intervalMs: intervalMs,
          resType: resType,
          charset: charset);
      if (response.resultStatus != EnumServerResponseStatus.success) {
        throw Exception('Server responded with ${response.resBody}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorReporter] Error report failed: $e');
      }
      if (_onSendFailure != null) {
        await _onSendFailure!(reportData);
      }
    }
  }
}
