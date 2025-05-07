/// (en) This is an object for storing basic error content used by
/// ErrorReporter and ErrorReporterForNative.
///
/// (ja) ErrorReporter、及びErrorReporterForNativeで利用される
/// 基本的なエラー内容を格納するためのオブジェクトです。
class ErrorReportObj {
  String appVersion;
  String errorMsg;
  String? stackTrace;
  String timestamp;
  Map<String, dynamic>? extraInfo;
  Map<String, dynamic>? customExtraInfo;

  /// * [appVersion] : Frontend app version.
  /// * [errorMsg] : The error message.
  /// * [stackTrace] : The stacktrace.
  /// * [timestamp] : Timestamp. The time is sent based on
  /// the user's local time, but it is recommended that you include
  /// the server time when saving, or overwrite it with the server time.
  /// * [extraInfo] : Additional information common to this app that is added
  /// during initialization, such as the app's platform information.
  /// * [customExtraInfo] : When reporting an individual error,
  /// additional information, such as the location of the error, is added.
  ErrorReportObj(this.appVersion, this.errorMsg, this.stackTrace,
      this.timestamp, this.extraInfo, this.customExtraInfo);

  /// (en) Convert to dict.
  ///
  /// (ja) 辞書に変換して返します。
  Map<String, dynamic> toDict() {
    return {
      "app_version": appVersion,
      "error_msg": errorMsg,
      "stacktrace": stackTrace,
      "timestamp": timestamp,
      "extra_info": extraInfo,
      "custom_extra_info": customExtraInfo,
    };
  }
}
