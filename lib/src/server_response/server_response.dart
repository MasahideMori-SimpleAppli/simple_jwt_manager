import 'package:http/http.dart' as http;

import 'enum_server_response_status.dart';

/// (en) This class is used to store return values from the server.
/// It stores statuses categorized in an easy to use way.
///
/// (ja) サーバーからの戻り値格納用クラスです。
/// 利用しやすい形で分類されたステータスが格納されます。
///
/// Author Masahide Mori
///
/// First edition creation date 2024-10-29 17:36:24
class ServerResponse {
  final http.Response? response;
  final EnumSeverResponseStatus resultStatus;
  final Map<String, dynamic>? resBody;
  final String? errorDetail;

  /// * [response] : Http response object.
  /// * [resultStatus] : The result status.
  /// * [resBody] :　The json decode server response body.
  /// * [errorDetail] : If there is a hint about the error content,
  /// it will be assigned.
  ServerResponse(
      this.response, this.resultStatus, this.resBody, this.errorDetail);

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
  errorDetail: ${errorDetail ?? 'N/A'}
}''';
  }
}
