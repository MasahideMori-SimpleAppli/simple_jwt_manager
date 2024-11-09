import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:simple_jwt_manager/src/server_response/server_response.dart';

import 'enum_server_response_status.dart';

/// サーバー応答を一定のフォーマットに沿って整形するためのユーティリティです。
class UtilServerResponse {
  /// 成功時のサーバー応答オブジェクトを作成します。
  static ServerResponse success(http.Response response) {
    return ServerResponse(response, EnumSeverResponseStatus.success,
        jsonDecode(response.body), null);
  }

  /// サーバーエラー時のサーバー応答オブジェクトを作成します。
  static ServerResponse serverError(http.Response response) {
    String errorDescription = "";
    Map<String, dynamic> errorBody = {};
    try {
      errorBody = jsonDecode(response.body);
      errorDescription = errorBody["error_description"];
    } catch (e) {
      errorDescription = "Unknown exception.";
    }
    return ServerResponse(response, EnumSeverResponseStatus.serverError,
        errorBody, errorDescription);
  }

  /// タイムアウト時のサーバー応答オブジェクトを作成します。
  static ServerResponse timeout() {
    return ServerResponse(null, EnumSeverResponseStatus.timeout, null, null);
  }

  /// 認証が必要になった時のサーバー応答オブジェクトを作成します。
  static ServerResponse signInRequired() {
    return ServerResponse(
        null, EnumSeverResponseStatus.signInRequired, null, null);
  }

  /// 通信エラーを含む、その他のエラー発生時のサーバー応答オブジェクトを作成します。
  static ServerResponse otherError(Object e) {
    return ServerResponse(
        null, EnumSeverResponseStatus.otherError, null, e.toString());
  }
}
