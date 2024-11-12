import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_jwt_manager/src/server_response/enum_server_response_status.dart';
import 'package:simple_jwt_manager/src/server_response/server_response.dart';
import 'package:simple_jwt_manager/src/server_response/util_server_response.dart';
import 'package:simple_jwt_manager/src/static_fields/f_grant_type.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_from_server.dart';
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
/// First edition creation date 2024-11-10 18:07:03
class ROPCClient {
  // static parameters
  static const String className = "ROPCClient";
  static const int version = 2;

  // parameters
  late final String _registerUrl;
  late final String _signInUrl;
  late final String _refreshUrl;
  late final String _revokeURL;
  late final String _deleteUserURL;
  late final Duration _timeout;

  // tokens
  String? _accessToken;
  String? _refreshToken;
  int? _accessTokenExpireUnixMS;
  String? _scope;
  String? _tokenType;

  // methods
  /// (en) This is an initialization function. All endpoints must support HTTPS.
  /// If you pass a URL that does not start with HTTPS,
  /// an exception will be thrown.
  ///
  /// (ja) 初期化関数です。エンドポイントは全てHTTPSに対応している必要があります。
  /// HTTPSから始まらないURLを渡した場合は例外がスローされます。
  ///
  /// * [registerURL] : The user register URL.
  /// * [signInURL] : The authentication URL.
  /// * [refreshURL] : A URL for reissuing a token using a refresh token.
  /// * [signOutURL] : The URL for signOut (revoke) the token.
  /// * [deleteUserURL] : This is the URL for deleting a user.
  /// * [timeout] : Timeout period for server access. Default is 1 min.
  /// * [tokens] : If there is token information previously saved by
  /// this class's toDict function, you can restore the token by setting it.
  ROPCClient(
      {required String registerURL,
      required String signInURL,
      required String refreshURL,
      required String signOutURL,
      required String deleteUserURL,
      Duration? timeout,
      Map<String, dynamic>? tokens}) {
    _registerUrl = UtilCheckURL.validateHttpsUrl(registerURL);
    _signInUrl = UtilCheckURL.validateHttpsUrl(signInURL);
    _refreshUrl = UtilCheckURL.validateHttpsUrl(refreshURL);
    _revokeURL = UtilCheckURL.validateHttpsUrl(signOutURL);
    _deleteUserURL = UtilCheckURL.validateHttpsUrl(deleteUserURL);
    _timeout = timeout ?? const Duration(minutes: 1);
    if (tokens != null) {
      _accessToken = tokens["access_token"];
      _accessTokenExpireUnixMS = tokens["access_token_expire_unix_ms"];
      _scope = tokens["scope"];
      _tokenType = tokens["token_type"];
      _refreshToken = tokens["refresh_token"];
    }
  }

  /// (en) Returns the token-related information held by
  /// this class in dictionary format.
  /// This can be used to store token information in your app, but
  /// you need to be careful about security.
  ///
  ///
  /// (ja) このクラスの保持するトークン関連情報を辞書形式で返します。
  /// これはアプリでのトークン情報を保存に利用できますが、
  /// セキュリティには気をつける必要があります。
  Map<String, dynamic> toDict() {
    return {
      "class_name": ROPCClient.className,
      "version": ROPCClient.version,
      "access_token": _accessToken,
      "access_token_expire_unix_ms": _accessTokenExpireUnixMS,
      "scope": _scope,
      "token_type": _tokenType,
      "refresh_token": _refreshToken,
    };
  }

  /// (en) Returns whether the user is currently signed in.
  /// This is determined by whether a refresh token is present.
  ///
  /// (ja) 現在サインイン状態かどうかを返します。
  /// 判定はリフレッシュトークンの有無で判断されます。
  bool isSignedIn() {
    return _refreshToken != null;
  }

  /// (en) Returns the refresh token.
  /// However, if the token has not yet been obtained, null is returned.
  ///
  /// (ja) 保持しているリフレッシュトークンを返します。
  /// ただし、まだ取得していない場合等はnullが返されます。
  String? getRefreshTokenBuff() {
    return _refreshToken;
  }

  /// (en) Returns the access token.
  /// This should only be used to determine specific conditions,
  /// such as when sign-out has failed.
  ///
  /// (ja) 保持しているアクセストークンを返します。
  /// これはサインアウトに失敗した場合など、特定の状況を判定する場合にのみ使用してください。
  String? getAccessTokenBuff() {
    return _accessToken;
  }

  /// (en) Returns the scope information of the held access token, if any.
  /// This is filled in only if scope information is returned by the server.
  ///
  /// (ja) 保持しているアクセストークンのスコープ情報があれば返します。
  /// これはサーバーからスコープ情報が返される場合にのみ値が入ります。
  String? getAccessTokenScopeBuff() {
    return _scope;
  }

  /// (en) Returns the type of the held access token, if any.
  ///
  /// (ja) 保持しているアクセストークンのタイプ情報があれば返します。
  String? getAccessTokenType() {
    return _tokenType;
  }

  /// (en) This performs the user registration process.
  /// This process is not defined in OAuth2.0,
  /// so it must be implemented uniquely for your application.
  /// In the implementation of this package,
  /// information is POSTed in JSON to the registerUrl.
  /// The expected return from the server is JSON:
  /// {"access_token": String? token, "expires_in": int? ms,
  /// "refresh_token": String? token}.
  /// The return token is buffered and maintained within this class.
  /// If the return value does not contain a token, the access success flag
  /// will be returned and the token will not be updated.
  ///
  /// (ja) ユーザー登録プロセスを実行します。
  /// このプロセスは OAuth2.0 では定義されていないため、
  /// アプリケーションごとに独自に実装する必要があります。
  /// 本ペッケージの実装ではregisterUrlに対してJSONで情報がPOSTされます。
  /// サーバーからの期待される戻り値はJSONで、
  /// ｛"access_token": String? token, "expires_in": int? ms,
  /// "refresh_token": String? token｝です。
  /// 戻り値のトークンはこのクラス内で取得され、保持されます。
  /// 戻り値にトークンが含まれない場合はアクセス成功フラグが返され、トークンは更新されません。
  ///
  /// * [email] : User mail address. It is used as an ID(User name).
  /// * [password] : pw.
  /// * [scope] : Application specific access permissions passed
  /// in space separated format, e.g. read write, user:follow, etc.
  /// * [name] : User name. This is personal information.
  /// * [nickname] : User Nickname.
  /// * [option] : Other optional parameters.
  Future<ServerResponse> register(String email, String password,
      {String? scope,
      String? name,
      String? nickname,
      Map<String, dynamic>? option}) async {
    try {
      final response = await http
          .post(
            Uri.parse(_registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              FJsonKeysToServer.username: email,
              FJsonKeysToServer.password: password,
              FJsonKeysToServer.scope: scope,
              FJsonKeysToServer.name: name,
              FJsonKeysToServer.nickname: nickname,
              FJsonKeysToServer.option: option
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        try {
          // サーバーがトークンを返す仕様の場合は取得してログイン状態にする
          final Map<String, dynamic> tokens = jsonDecode(response.body);
          _updateJWTBuff(tokens);
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

  /// (en) Executes the user deletion process.
  /// This process is not defined in OAuth2.0,
  /// so it must be implemented independently for each application.
  /// In the implementation of this package,
  /// information is POSTed in JSON to the deleteUserURL.
  ///
  /// (ja) ユーザーの削除プロセスを実行します。
  /// このプロセスは OAuth2.0 では定義されていないため、
  /// アプリケーションごとに独自に実装する必要があります。
  /// 本ペッケージの実装ではdeleteUserURLに対してJSONで情報がPOSTされます。
  ///
  /// * [email] : User mail address. It is used as an ID(User name).
  /// * [password] : pw.
  /// * [option] : Other optional parameters.
  Future<ServerResponse> deleteUser(String email, String password,
      {Map<String, dynamic>? option}) async {
    try {
      final response = await http
          .post(
            Uri.parse(_deleteUserURL),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              FJsonKeysToServer.username: email,
              FJsonKeysToServer.password: password,
              FJsonKeysToServer.option: option
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        _clearToken();
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

  /// 取得したトークンなどの情報をこのクラスに保存します。
  void _updateJWTBuff(Map<String, dynamic> tokens) {
    final int nowUnixTimeMS = DateTime.now().millisecondsSinceEpoch;
    if (tokens.containsKey(FJsonKeysFromServer.accessToken)) {
      _accessToken = tokens[FJsonKeysFromServer.accessToken];
    }
    if (tokens.containsKey(FJsonKeysFromServer.expiresIn)) {
      _accessTokenExpireUnixMS = nowUnixTimeMS +
          (int.parse(tokens[FJsonKeysFromServer.expiresIn].toString()) * 1000);
    }
    if (tokens.containsKey(FJsonKeysFromServer.scope)) {
      _scope = tokens[FJsonKeysFromServer.scope];
    }
    if (tokens.containsKey(FJsonKeysFromServer.tokenType)) {
      _tokenType = tokens[FJsonKeysFromServer.tokenType];
    }
    if (tokens.containsKey(FJsonKeysFromServer.refreshToken)) {
      _refreshToken = tokens[FJsonKeysFromServer.refreshToken];
    }
  }

  /// (en) Obtain a token using
  /// the OAuth 2.0 "Resource Owner Password Credentials Grant" process.
  ///
  /// (ja) OAuth 2.0の「Resource Owner Password Credentials Grant」の処理で
  /// トークンを取得します。
  ///
  /// * [email] : User mail address. It is used as an ID(User name).
  /// * [password] : pw.
  /// * [scope] : Application specific access permissions passed
  /// in space separated format, e.g. read write, user:follow, etc.
  Future<ServerResponse> signIn(String email, String password,
      {String? scope}) async {
    try {
      final response = await http.post(
        Uri.parse(_signInUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          FJsonKeysToServer.grantType: FGrantType.password,
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.scope: scope,
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        // トークンを取得して保存
        final Map<String, dynamic> tokens = jsonDecode(response.body);
        _updateJWTBuff(tokens);
        // 必須パラメータの返却チェック
        if (_accessToken == null || _tokenType == null) {
          return UtilServerResponse.otherError(
              "OAuth 2.0 response error: missing token or token_type");
        }
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

  /// (en) Performs sign-out processing as specified in RFC 7009.
  /// This is a simplified version
  /// that invalidates the refresh token and access token in succession.
  /// If an error occurs along the way,
  /// an error will simply be returned,
  /// which may make it difficult to understand the situation.
  ///
  /// (ja) RFC 7009の仕様の通り、サインアウト処理を行います。
  /// これは簡易版で、リフレッシュトークンとアクセストークンを連続で失効処理します。
  /// 途中で何らかのエラーが発生した場合は、単にエラーが返されます。
  /// 処理が失敗した場合、どちらの失効リクエストが失敗したのかを判断するには、
  Future<ServerResponse> signOutAllTokens() async {
    ServerResponse res = await signOut(isRefreshToken: true);
    switch (res.resultStatus) {
      case EnumSeverResponseStatus.success:
        return await signOut(isRefreshToken: false);
      case EnumSeverResponseStatus.timeout:
      case EnumSeverResponseStatus.serverError:
      case EnumSeverResponseStatus.otherError:
      case EnumSeverResponseStatus.signInRequired:
        return res;
    }
  }

  /// (en) Performs sign-out processing in accordance with
  /// the RFC 7009 specifications.
  /// Normally, a two-step process is required:
  /// first send a request to invalidate
  /// the refresh token (isRefreshToken = true),
  /// then send a request to invalidate
  /// the access token (isRefreshToken = false).
  /// If you want strict control,
  /// process in two steps while changing the arguments of this function.
  /// You can use signOutAllTokens for a simple implementation,
  /// but signOutAllTokens cannot handle individual errors.
  ///
  /// (ja) RFC 7009の仕様の通り、サインアウト処理を行います。
  /// 通常は、まずリフレッシュトークンの無効化リクエストを送信（isRefreshToken = true）し、
  /// 続けてアクセストークンの無効化リクエストを送信(isRefreshToken = false)
  /// する２段階の処理が必要です。
  /// 厳密に制御したい場合はこの関数の引数を変更しつつ２段階で処理してください。
  /// 簡易に実装したい場合はsignOutAllTokensを利用できますが、
  /// signOutAllTokensは個別のエラーには対応できません。
  ///
  /// * [isRefreshToken] : If true, invalidates the server-side refresh token.
  /// If it is false, the access token will be invalidated.
  Future<ServerResponse> signOut({bool isRefreshToken = true}) async {
    Map<String, dynamic> target = {};
    if (isRefreshToken) {
      target = {
        FJsonKeysToServer.tokenTypeHint: FJsonKeysToServer.refreshToken,
        FJsonKeysToServer.refreshToken: _refreshToken,
      };
    } else {
      target = {
        FJsonKeysToServer.tokenTypeHint: FJsonKeysToServer.accessToken,
        FJsonKeysToServer.accessToken: _accessToken,
      };
    }
    try {
      final response = await http
          .post(
            Uri.parse(_revokeURL),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: target,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        if (isRefreshToken) {
          _refreshToken = null;
        } else {
          _accessToken = null;
          _accessTokenExpireUnixMS = null;
          _scope = null;
          _tokenType = null;
        }
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

  /// (en) Gets a JWT token.
  /// If the cached token has not yet expired, the cached token is returned.
  /// If the token has expired, an attempt is made to refresh
  /// it using the refresh token,
  /// but if that fails, null is returned.
  /// Also, null is returned if the user is not signed in.
  ///
  /// (ja) JWTトークンを取得します。
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
        debugPrint(res.error);
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
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        try {
          // トークンを取得して保存
          final Map<String, dynamic> tokens = jsonDecode(response.body);
          _updateJWTBuff(tokens);
          // 必須パラメータの返却チェック
          if (_accessToken == null || _tokenType == null) {
            return UtilServerResponse.otherError(
                "OAuth 2.0 response error: missing token or token_type");
          }
          return UtilServerResponse.success(response);
        } catch (e) {
          return UtilServerResponse.otherError('Invalid token format');
        }
      } else {
        // リフレッシュトークンが期限切れの場合、クライアント側のトークンをクリアする
        if (response.statusCode == 401) {
          _clearToken();
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

  /// ローカルのアクセストークン、及びリフレッシュトークンをクリアします。
  void _clearToken() {
    _accessToken = null;
    _accessTokenExpireUnixMS = null;
    _scope = null;
    _tokenType = null;
    _refreshToken = null;
  }
}
