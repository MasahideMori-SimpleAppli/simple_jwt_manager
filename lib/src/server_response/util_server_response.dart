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

  /// (en) Creates a server response object in case of a server error.
  ///
  /// (ja) サーバーエラー時のサーバー応答オブジェクトを作成します。
  static ServerResponse serverError(http.Response response) {
    String errorDescription = "";
    Map<String, dynamic> errorBody = {};
    try {
      errorBody = jsonDecode(response.body);
      errorDescription = errorBody["error_description"];
    } catch (e) {
      errorDescription = "Server error. ${response.body}";
    }
    return ServerResponse(response, EnumSeverResponseStatus.serverError,
        errorBody, errorDescription);
  }

  /// (en) Creates a timeout server response object.
  ///
  /// (ja) タイムアウト時のサーバー応答オブジェクトを作成します。
  ///
  /// * [e] : The error message.
  static ServerResponse timeout(String e) {
    return ServerResponse(null, EnumSeverResponseStatus.timeout, null, e);
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
