import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:simple_jwt_manager/src/server_response/server_response.dart';

import 'enum_server_response_status.dart';

/// (en) A utility for formatting server responses.
///
/// (ja)サーバー応答を一定のフォーマットに沿って整形するためのユーティリティです。
class UtilServerResponse {
  /// (en) Creates a successful server response object.
  ///
  /// (ja) 成功時のサーバー応答オブジェクトを作成します。
  static ServerResponse success(http.Response response) {
    return ServerResponse(response, EnumSeverResponseStatus.success,
        jsonDecode(response.body), null);
  }

  /// (en) Creates a server response object in case of a server exception.
  ///
  /// (ja) サーバー例外時のサーバー応答オブジェクトを作成します。
  static ServerResponse serverException(http.Response response) {
    String errorDescription = "";
    Map<String, dynamic> errorBody = {};
    try {
      errorBody = jsonDecode(response.body);
      errorDescription = errorBody["error_description"];
    } catch (e) {
      errorDescription = "Server exception. ${response.body}";
    }
    return ServerResponse(response, EnumSeverResponseStatus.serverException,
        errorBody, errorDescription);
  }

  /// (en) Creates a timeout server response object.
  ///
  /// (ja) タイムアウト時のサーバー応答オブジェクトを作成します。
  ///
  /// * [isConnectionTimeout] : If true, connection timeout.
  /// other is response timeout.
  /// * [e] : The error message.
  static ServerResponse timeout(bool isConnectionTimeout, String e) {
    return ServerResponse(
        null,
        EnumSeverResponseStatus.timeout,
        null,
        isConnectionTimeout
            ? "Connection timeout. $e"
            : "Response timeout. $e");
  }

  /// (en) Creates a server response object when authentication is required.
  ///
  /// (ja) 認証が必要になった時のサーバー応答オブジェクトを作成します。
  static ServerResponse signInRequired() {
    return ServerResponse(
        null, EnumSeverResponseStatus.signInRequired, null, null);
  }

  /// (en) Creates a server response object for any other error that occurs,
  /// including communication errors.
  ///
  /// (ja) 通信エラーを含む、その他のエラー発生時のサーバー応答オブジェクトを作成します。
  static ServerResponse otherError(Object e) {
    return ServerResponse(
        null, EnumSeverResponseStatus.otherError, null, e.toString());
  }
}
