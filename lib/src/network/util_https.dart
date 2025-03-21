import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../simple_jwt_manager.dart';

class UtilHttps {
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
  /// * [timeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls that is
  /// automatically adjusted if adjustTiming is True.
  /// If consecutive calls are made earlier than this,
  /// they will wait until this interval before being executed.
  /// The unit is milliseconds.
  static Future<ServerResponse> post(
      String url, Map<String, dynamic> body, EnumPostEncodeType type,
      {String? jwt,
      Duration timeout = const Duration(seconds: 10),
      bool adjustTiming = true,
      intervalMs = 1200}) async {
    Map<String, String> headers = {};
    if (jwt != null) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    switch (type) {
      case EnumPostEncodeType.urlEncoded:
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        return customPost(url, Uri(queryParameters: body).query, headers,
            timeout: timeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs);
      case EnumPostEncodeType.json:
        headers['Content-Type'] = 'application/json';
        return customPost(url, jsonEncode(body), headers,
            timeout: timeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs);
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
  /// * [body] : Map&lt;String, dynamic&gt;, Json encoded string, or List&lt;int&gt;.
  /// * [headers] : HTTP headers.
  /// * [encoding] : The data encoding.
  /// * [timeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls that is
  /// automatically adjusted if adjustTiming is True.
  /// If consecutive calls are made earlier than this,
  /// they will wait until this interval before being executed.
  /// The unit is milliseconds.
  static Future<ServerResponse> customPost(
      String url, Object? body, Map<String, String> headers,
      {Encoding? encoding,
      Duration timeout = const Duration(seconds: 10),
      bool adjustTiming = true,
      intervalMs = 1200}) async {
    try {
      if (adjustTiming) {
        await TimingManager().adjustTiming(intervalMs: intervalMs);
      }
      final String httpsURL = UtilCheckURL.validateHttpsUrl(url);
      final http.Response r = await http
          .post(Uri.parse(httpsURL),
              headers: headers, body: body, encoding: encoding)
          .timeout(timeout);
      if (r.statusCode == 200) {
        return UtilServerResponse.success(r);
      } else {
        return UtilServerResponse.serverError(r);
      }
    } on TimeoutException catch (e) {
      // response timeout
      return UtilServerResponse.timeout(e);
    } catch (e) {
      return UtilServerResponse.otherError(e);
    }
  }
}
