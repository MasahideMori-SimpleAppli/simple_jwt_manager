import 'package:http/http.dart' as http;
import 'package:simple_jwt_manager/simple_jwt_manager.dart';
import 'dart:convert';

/// (en) A utility for formatting server responses.
///
/// (ja)サーバー応答を一定のフォーマットに沿って整形するためのユーティリティです。
class UtilServerResponse {
  /// (en) Creates a successful server response object.
  ///
  /// (ja) 成功時のサーバー応答オブジェクトを作成します。
  ///
  /// * [res] : The server response.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the format { "r" : UTF-8 text }.
  static ServerResponse success(http.Response res,
      {EnumServerResponseType resType = EnumServerResponseType.json}) {
    switch (resType) {
      case EnumServerResponseType.json:
        return ServerResponse(
            res, EnumServerResponseStatus.success, jsonDecode(res.body), null);
      case EnumServerResponseType.byte:
        return ServerResponse(
            res, EnumServerResponseStatus.success, {"r": res.bodyBytes}, null);
      case EnumServerResponseType.text:
        return ServerResponse(
            res, EnumServerResponseStatus.success, {"r": res.body}, null);
    }
  }

  /// (en) Creates a server response object in case of a server error.
  ///
  /// (ja) サーバーエラー時のサーバー応答オブジェクトを作成します。
  ///
  /// * [res] : The server response.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the format { "r" : UTF-8 text }.
  static ServerResponse serverError(http.Response res,
      {EnumServerResponseType resType = EnumServerResponseType.json}) {
    String errorDescription = "";
    Map<String, dynamic> errorBody = {};
    switch (resType) {
      case EnumServerResponseType.json:
        try {
          errorBody = jsonDecode(res.body);
          errorDescription = errorBody["error_description"] ?? "Server error.";
        } catch (e) {
          errorDescription = "Server error. ${res.body}";
        }
        break;
      case EnumServerResponseType.byte:
        try {
          errorBody = {"r": res.bodyBytes};
          errorDescription = errorBody["error_description"] ?? "Server error.";
        } catch (e) {
          errorDescription = "Server error. ${res.body}";
        }
        break;
      case EnumServerResponseType.text:
        try {
          errorBody = {"r": res.body};
          errorDescription = errorBody["error_description"] ?? "Server error.";
        } catch (e) {
          errorDescription = "Server error. ${res.body}";
        }
        break;
    }
    return ServerResponse(
        res, EnumServerResponseStatus.serverError, errorBody, errorDescription);
  }

  /// (en) Creates a timeout server response object.
  ///
  /// (ja) タイムアウト時のサーバー応答オブジェクトを作成します。
  ///
  /// * [e] : The error object that contains the error message.
  static ServerResponse timeout(Object e) {
    return ServerResponse(
        null, EnumServerResponseStatus.timeout, null, e.toString());
  }

  /// (en) Creates a server response object when authentication is required.
  ///
  /// (ja) 認証が必要になった時のサーバー応答オブジェクトを作成します。
  ///
  /// * [res] : The server response.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the format { "r" : UTF-8 text }.
  static ServerResponse signInRequired(
      {http.Response? res,
      EnumServerResponseType resType = EnumServerResponseType.json}) {
    switch (resType) {
      case EnumServerResponseType.json:
        try {
          return ServerResponse(res, EnumServerResponseStatus.signInRequired,
              res != null ? jsonDecode(res.body) : null, "Unauthenticated.");
        } catch (e) {
          return ServerResponse(res, EnumServerResponseStatus.signInRequired,
              {"r": "JSON decode error."}, "Unauthenticated.");
        }
      case EnumServerResponseType.byte:
        return ServerResponse(res, EnumServerResponseStatus.signInRequired,
            {"r": res?.bodyBytes}, "Unauthenticated.");
      case EnumServerResponseType.text:
        return ServerResponse(res, EnumServerResponseStatus.signInRequired,
            {"r": res?.body}, "Unauthenticated.");
    }
  }

  /// (en) Creates a server response object for any other error.
  ///
  /// (ja) その他のエラー発生時のサーバー応答オブジェクトを作成します。
  ///
  /// * [e] : The error object that contains the error message.
  static ServerResponse otherError(Object e) {
    return ServerResponse(
        null, EnumServerResponseStatus.otherError, null, e.toString());
  }
}
