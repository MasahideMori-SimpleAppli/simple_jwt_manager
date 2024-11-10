import 'package:http/http.dart' as http;

import 'enum_server_response_status.dart';

/// (en) This class is used to store return values from the server.
/// In addition to statuses categorized in an easy-to-use format,
/// it also stores error codes, etc.
///
/// (ja) サーバーからの戻り値格納用クラスです。
/// 利用しやすい形で分類されたステータスの他に、エラーコードなども格納されます。
///
/// Author Masahide Mori
///
/// First edition creation date 2024-10-29 17:36:24
class ServerResponse {
  final http.Response? response;
  final EnumSeverResponseStatus resultStatus;
  final Map<String, dynamic>? resBody;
  final String? error;

  /// * [response] : Http response object.
  /// * [isTokenExpired] : If true, the token has expired and a login process
  /// is required.
  /// * [isTimeOut] : If true, request timeout occurred.
  /// * [resBody] :　The json decode server response body.
  /// * [error] : Null if no error occurred.
  /// It will also be null on timeout.
  ServerResponse(this.response, this.resultStatus, this.resBody, this.error);

  @override
  String toString() {
    return '''
ServerResponse {
  resultStatus: $resultStatus,
  response: {
    statusCode: ${response?.statusCode ?? 'N/A'},
    reasonPhrase: ${response?.reasonPhrase ?? 'N/A'}
  },
  resBody: ${resBody != null ? resBody.toString() : 'N/A'},
  error: ${error ?? 'N/A'}
}''';
  }
}
