import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:simple_jwt_manager/src/server_response/util_server_response.dart';

import '../../simple_jwt_manager.dart';

class UtilHttpsClient {
  /// (en) Converts a map to a JSON string.
  ///
  /// (ja) JSON文字列に変換します。
  static String toJson(Map<String, dynamic> m) {
    return jsonEncode(m);
  }

  /// (en) Converts a map to a URL-encoded string.
  ///
  /// (ja) URLエンコードされた文字列に変換します。
  static String toURLEncoded(Map<String, dynamic> m) {
    return Uri(queryParameters: m).query;
  }

  /// TODO : postの簡単なバージョンも作成する。

  /// (en) Build the https and POST it.
  ///
  /// (ja) Httpsを構築してPOSTします。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [body] : JSON encoded string, URL encoded string or int list etc.
  /// Data formats can be converted using the utility's toXXX methods.
  /// * [headers] : HTTP headers.
  static Future<ServerResponse> post(
    String url,
    Object body,
    Map<String, List<String>> headers, {
    bool Function(X509Certificate cert, String host, int port)?
        badCertificateCallback,
    int connectionTimeoutSec = 10,
    int responseTimeoutSec = 10,
  }) async {
    final HttpClient client = HttpClient();
    if (badCertificateCallback != null) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              badCertificateCallback(cert, host, port);
    }
    // 接続タイムアウトの設定。これはサーバーが応答するかどうかの部分。
    client.connectionTimeout = Duration(seconds: connectionTimeoutSec);
    try {
      final String httpsURL = UtilCheckURL.validateHttpsUrl(url);
      HttpClientRequest request = await client.postUrl(Uri.parse(httpsURL));
      // ヘッダー設定
      headers.forEach((key, values) {
        for (final v in values) {
          request.headers.add(key, v); // 複数の値を設定
        }
      });
      request.write(body);
      // レスポンスを受け取る。ここでのタイムアウトは、データが戻ってくるまでの時間にかかる。
      final HttpClientResponse res =
          await request.close().timeout(Duration(seconds: responseTimeoutSec));
      final http.Response r = await _convertHttpClientResponseToResponse(res);
      if (r.statusCode == 200) {
        return UtilServerResponse.success(r);
      } else {
        return UtilServerResponse.serverException(r);
      }
    } on SocketException catch (e) {
      return UtilServerResponse.timeout(true, e.toString());
    } on TimeoutException catch (e) {
      return UtilServerResponse.timeout(false, e.toString());
    } catch (e) {
      return UtilServerResponse.otherError(e);
    } finally {
      client.close();
    }
  }

  /// HttpClientResponseを利用しやすいResponseに変換する。
  static Future<http.Response> _convertHttpClientResponseToResponse(
      HttpClientResponse httpClientResponse) async {
    // ボディを取得
    final body = await utf8.decoder.bind(httpClientResponse).join();
    // ヘッダーを変換
    final headers = <String, String>{};
    httpClientResponse.headers.forEach((key, values) {
      headers[key] = values.join(', ');
    });
    // http.Responseを生成
    return http.Response(
      body,
      httpClientResponse.statusCode,
      headers: headers,
      request: null,
    );
  }
}
