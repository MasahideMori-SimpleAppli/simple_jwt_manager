import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:simple_jwt_manager/src/server_response/enum_server_response_status.dart';
import 'package:simple_jwt_manager/src/server_response/server_response.dart';
import 'package:simple_jwt_manager/src/server_response/util_server_response.dart';
import 'package:simple_jwt_manager/src/static_fields/f_grant_type.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_to_server.dart';
import 'package:simple_jwt_manager/src/util/util_check_url.dart';

/// (en) This class manages JWT tokens and controls login, as defined in
/// the Resource Owner Password Credentials Grant defined in RFC 6749.
///
/// (ja) Resource Owner Password Credentials Grant defined in RFC 6749における、
/// JWTトークンの管理とログイン制御のためのクラスです。
///
/// Author Masahide Mori
///
/// First edition creation date 2024-10-28 20:29:00(now creating)
class ROPCGClient {
  // parameters
  late final String _registerUrl;
  late final String _signInUrl;
  late final String _refreshUrl;
  late final String _signOutURL;
  late final String? _clientID;
  late final String? _clientSecret;
  late final Duration _timeout;

  // tokens
  String? _accessToken;
  String? _refreshToken;
  int? _accessTokenExpireUnixMS;

  // methods
  /// (en) This is an initialization function. If the endpoint URL is not null,
  /// it will be configured to access the specified server.
  ///
  /// (ja) 初期化関数です。エンドポイントURLがnullではない場合、
  /// 指定サーバーに対してアクセスを行うように構成されます。
  ///
  /// * [registerURL] : The user register URL.
  /// * [signInURL] : The authentication URL.
  /// * [refreshURL] : A URL for reissuing a token using a refresh token.
  /// * [signOutURL] : The URL for signOut (revoke) the token.
  /// * [clientID] : Client ID such as the app name. In this implementation,
  /// use a name that you don't mind leaking to the outside.
  /// * [clientSecret] : The client secret key,
  /// which must never be leaked and is only available for server-side use.
  /// If you are using it on the front end, set it to null.
  /// * [timeout] : Timeout period for server access.
  ROPCGClient(
      {required String registerURL,
        required String signInURL,
        required String refreshURL,
        required String signOutURL,
        String? clientID,
        String? clientSecret,
        Duration? timeout}) {
    _registerUrl = UtilCheckURL.validateHttpsUrl(registerURL);
    _signInUrl = UtilCheckURL.validateHttpsUrl(signInURL);
    _refreshUrl = UtilCheckURL.validateHttpsUrl(refreshURL);
    _signOutURL = UtilCheckURL.validateHttpsUrl(signOutURL);
    _clientID = clientID;
    _clientSecret = clientSecret;
    _timeout = timeout ?? const Duration(minutes: 1);
  }

  /// 現在サインイン状態かどうかを返します。
  /// 判定はリフレッシュトークンの有無で判断されます。
  bool isSignedIn() {
    return _refreshToken != null;
  }

  /// リフレッシュトークンを返します。ただし、まだ取得していない場合はnullが返されます。
  /// これは主にサインイン状態を維持したい時に、リフレッシュトークンを保存するために使用します。
  /// ただし、セキュリティには十分に気をつけてください。
  String? getRefreshToken() {
    return _refreshToken;
  }

  /// ユーザー登録処理を行います。
  /// * [email] : ユーザー識別のためのメールアドレス。
  /// * [password] : パスワード。
  /// * [name] : ユーザーの本名（オプション）。
  /// * [nickname] : ユーザーのニックネーム（オプション）。
  Future<ServerResponse> register(
      String email, String password, String? name, String? nickname) async {
    try {
      final response = await http
          .post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.name: name,
          FJsonKeysToServer.nickname: nickname,
          FJsonKeysToServer.clientID: _clientID,
          FJsonKeysToServer.clientSecret: _clientSecret,
        }),
      )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        // サーバーがトークンを返す仕様の場合は取得してログイン状態にする
        final int nowUnixTimeMS = DateTime.now().millisecondsSinceEpoch;
        try {
          final Map<String, dynamic> tokens = jsonDecode(response.body);
          if (tokens.containsKey(FJsonKeysFromServer.accessToken)) {
            _accessToken = tokens[FJsonKeysFromServer.accessToken];
            _accessTokenExpireUnixMS = nowUnixTimeMS +
                (int.parse(tokens[FJsonKeysFromServer.expiresIn].toString()) *
                    1000);
          }
          if (tokens.containsKey(FJsonKeysFromServer.refreshToken)) {
            _refreshToken = tokens[FJsonKeysFromServer.refreshToken];
          }
          return UtilServerResponse.success(response);
        } catch (e) {
          // サーバーがトークンを返さない、または戻り値がJSONでは無いような場合。
          return UtilServerResponse.success(response);
        }
      } else {
        return UtilServerResponse.serverError(response);
      }
    } on TimeoutException catch (_) {
      return UtilServerResponse.timeout();
    } catch (e) {
      return UtilServerResponse.otherError(e);
    }
  }

  /// サインイン処理を行います。
  Future<ServerResponse> signIn(String email, String password) async {
    try {
      final response = await http
          .post(
        Uri.parse(_signInUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          FJsonKeysToServer.grantType: FGrantType.password,
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.clientID: _clientID,
          FJsonKeysToServer.clientSecret: _clientSecret,
        },
      )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        // トークンを取得して保存
        final int nowUnixTimeMS = DateTime.now().millisecondsSinceEpoch;
        final tokens = jsonDecode(response.body);
        _accessToken = tokens[FJsonKeysFromServer.accessToken];
        _accessTokenExpireUnixMS = nowUnixTimeMS +
            (int.parse(tokens[FJsonKeysFromServer.expiresIn].toString()) *
                1000);
        _refreshToken = tokens[FJsonKeysFromServer.refreshToken];
        return UtilServerResponse.success(response);
      } else {
        return UtilServerResponse.serverError(response);
      }
    } on TimeoutException catch (_) {
      return UtilServerResponse.timeout();
    } catch (e) {
      return UtilServerResponse.otherError(e);
    }
  }

  /// サインアウト処理を行います。
  /// リフレッシュトークンと共にアクセストークンも無効化され、
  /// 以降はサインインが必要になります。
  Future<DTDBServerResponse> signOut() async {
    try {
      final response = await http
          .post(
        Uri.parse(_signOutURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          FJsonKeysToServer.tokenTypeHint: FJsonKeysToServer.refreshToken,
          FJsonKeysToServer.refreshToken: _refreshToken,
          FJsonKeysToServer.clientID: _clientID,
          FJsonKeysToServer.clientSecret: _clientSecret,
        }),
      )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return UtilServerResponse.success(response);
      } else {
        return UtilServerResponse.serverError(response);
      }
    } on TimeoutException catch (_) {
      return UtilServerResponse.timeout();
    } catch (e) {
      return UtilServerResponse.otherError(e);
    }
  }

  /// JWTトークンを取得します。
  /// キャッシュされたトークンの期限が残っている場合、キャッシュされたトークンが返されます。
  /// トークンが期限切れの場合はリフレッシュトークンを使ってリフレッシュを試みますが、
  /// 失敗した場合はnullを返します。
  /// また、サインイン状態では無い場合もnullが返されます。
  Future<String?> getToken() async {
    if (_refreshToken == null) {
      return null;
    }
    if (_isTokenExpired()) {
      final ServerResponse res = await _refreshAndGetNewToken();
      if (res.resultStatus != EnumSeverResponseStatus.success) {
        return null;
      }
    }
    return _accessToken;
  }

  /// トークンの期限切れをチェックします。
  bool _isTokenExpired() {
    if (_accessTokenExpireUnixMS == null) return true;
    return DateTime.now().millisecondsSinceEpoch > _accessTokenExpireUnixMS!;
  }

  /// リフレッシュトークンを使用して新しいトークンを取得し、キャッシュします。
  Future<ServerResponse> _refreshAndGetNewToken() async {
    if (_refreshToken == null) {
      return UtilServerResponse.signInRequired();
    }
    // サーバーからトークンを取得
    try {
      final response = await http.post(
        Uri.parse(_refreshUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          FJsonKeysToServer.grantType: FGrantType.refreshToken,
          FJsonKeysToServer.refreshToken: _refreshToken,
          FJsonKeysToServer.clientID: _clientID,
          FJsonKeysToServer.clientSecret: _clientSecret,
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        // トークンを取得して保存
        final int nowUnixTimeMS = DateTime.now().millisecondsSinceEpoch;
        try {
          final Map<String, dynamic> tokens = jsonDecode(response.body);
          _accessToken = tokens[FJsonKeysFromServer.accessToken];
          _accessTokenExpireUnixMS = nowUnixTimeMS +
              (int.parse(tokens[FJsonKeysFromServer.expiresIn].toString()) *
                  1000);
          // リフレッシュトークンの交換がある場合は入れ替える。
          if (tokens.containsKey(FJsonKeysFromServer.refreshToken)) {
            _refreshToken = tokens[FJsonKeysFromServer.refreshToken];
          }
          return UtilServerResponse.success(response);
        } catch (e) {
          return UtilServerResponse.otherError('Invalid token format');
        }
      } else {
        // リフレッシュトークンが期限切れの場合、クライアント側のトークンをクリアする
        if (response.statusCode == 401) {
          clearToken();
          return UtilServerResponse.signInRequired();
        } else {
          return UtilServerResponse.serverError(response);
        }
      }
    } on TimeoutException catch (_) {
      return UtilServerResponse.timeout();
    } catch (e) {
      return UtilServerResponse.otherError(e);
    }
  }

  /// アクセストークン、及びリフレッシュトークンをクリアします。
  void clearToken() {
    _accessToken = null;
    _accessTokenExpireUnixMS = null;
    _refreshToken = null;
  }
}