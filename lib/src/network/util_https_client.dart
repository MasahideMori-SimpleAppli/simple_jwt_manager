import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:simple_jwt_manager/src/server_response/util_server_response.dart';

import '../../simple_jwt_manager.dart';

class UtilHttpsClient {
  /// (en) Build the https and POST it.
  ///
  /// (ja) Httpsを構築してPOSTします。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [body] : The data passed in the Map will be automatically
  /// encoded according to the enum specification.
  /// * [type] : Data passed in the map and the http headers are automatically
  /// encoded according to the enum specification.
  /// * [jwt] : The jwt. It is inserted into the Authorization header.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
  static Future<ServerResponse> post(
    String url,
    Map<String, dynamic> body,
    EnumPostEncodeType type, {
    String? jwt,
    bool Function(X509Certificate cert, String host, int port)?
        badCertificateCallback,
    Duration connectionTimeout = const Duration(seconds: 10),
    Duration responseTimeout = const Duration(seconds: 10),
  }) async {
    Map<String, String> headers = {};
    if (jwt != null) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    switch (type) {
      case EnumPostEncodeType.urlEncoded:
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        return customPost(url, body, headers,
            badCertificateCallback: badCertificateCallback,
            connectionTimeout: connectionTimeout,
            responseTimeout: responseTimeout);
      case EnumPostEncodeType.json:
        headers['Content-Type'] = 'application/json';
        return customPost(url, jsonEncode(body), headers,
            badCertificateCallback: badCertificateCallback,
            connectionTimeout: connectionTimeout,
            responseTimeout: responseTimeout);
    }
  }

  /// (en) Build the https and POST it.
  /// This is a more customizable version, if you want a quicker experience
  /// you can use post function instead.
  ///
  /// (ja) Httpsを構築してPOSTします。
  /// これはカスタマイズ性を高めたバージョンで、簡単に利用したい場合は代わりにpostが使えます。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [body] : Map<String, dynamic>, Json encoded string, or List<int>.
  /// * [headers] : HTTP headers.
  /// * [encoding] : The data encoding.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
  static Future<ServerResponse> customPost(
    String url,
    Object? body,
    Map<String, String> headers, {
    Encoding? encoding,
    bool Function(X509Certificate cert, String host, int port)?
        badCertificateCallback,
    Duration connectionTimeout = const Duration(seconds: 10),
    Duration responseTimeout = const Duration(seconds: 10),
  }) async {
    final HttpClient client = HttpClient();
    if (badCertificateCallback != null) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              badCertificateCallback(cert, host, port);
    }
    // 接続タイムアウトの設定。これはサーバー初期応答の部分。
    client.connectionTimeout = connectionTimeout;
    final ioClient = IOClient(client);
    try {
      final String httpsURL = UtilCheckURL.validateHttpsUrl(url);
      // ヘッダー設定
      final http.Response r = await ioClient
          .post(Uri.parse(httpsURL),
              headers: headers, body: body, encoding: encoding)
          .timeout(responseTimeout);
      if (r.statusCode == 200) {
        return UtilServerResponse.success(r);
      } else {
        return UtilServerResponse.serverException(r);
      }
    } on SocketException catch (e) {
      // connection timeout
      return UtilServerResponse.timeout(true, e.toString());
    } on TimeoutException catch (e) {
      // response timeout
      return UtilServerResponse.timeout(false, e.toString());
    } catch (e) {
      return UtilServerResponse.otherError(e);
    } finally {
      client.close();
    }
  }
}
