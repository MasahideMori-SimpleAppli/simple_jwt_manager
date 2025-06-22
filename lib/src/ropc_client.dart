import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';
import 'package:simple_jwt_manager/src/static_fields/f_grant_type.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_from_server.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_to_server.dart';

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
  static const int version = 10;

  // parameters
  late final String _registerUrl;
  late final String _signInUrl;
  late final String _refreshUrl;
  late final String _revokeURL;
  late final String _deleteUserURL;
  late final Duration _timeout;
  late final int refreshMarginMs;
  final void Function(Map<String, dynamic> savedData)? updateJwtCallback;
  final String? charset;

  // tokens
  String? _accessToken;
  String? _refreshToken;
  int? _accessTokenExpireUnixMS;
  String? _scope;
  String? _tokenType;

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
  /// * [charset] : Use this when you want to explicitly specify the charset in
  /// the HTTP header. If null, it will automatically be set to utf-8. Also,
  /// if you enter an empty string, no specification will be made.
  /// * [savedData] : If there is token information previously saved by
  /// this class's toDict function, you can restore the token by setting it.
  /// * [refreshMarginMs] : The access token expiration time will be estimated
  /// early by the margin you set here.
  /// By default, if the access token is due to expire within 30 seconds,
  /// it will be automatically refreshed using a refresh token.
  /// * [updateJwtCallback] : This is a callback that is called whenever
  /// a managed JWT is updated. It is called after a JWT is retrieved, replaced,
  /// or deleted.
  /// The result of the toDict call on this class is passed as an argument to
  /// the function, and can be saved to compose the savedData used on app restart
  /// that will be passed on app restart.
  ROPCClient(
      {required String registerURL,
      required String signInURL,
      required String refreshURL,
      required String signOutURL,
      required String deleteUserURL,
      Duration? timeout,
      this.charset,
      Map<String, dynamic>? savedData,
      this.refreshMarginMs = 30 * 1000,
      this.updateJwtCallback}) {
    _registerUrl = UtilCheckURL.validateHttpsUrl(registerURL);
    _signInUrl = UtilCheckURL.validateHttpsUrl(signInURL);
    _refreshUrl = UtilCheckURL.validateHttpsUrl(refreshURL);
    _revokeURL = UtilCheckURL.validateHttpsUrl(signOutURL);
    _deleteUserURL = UtilCheckURL.validateHttpsUrl(deleteUserURL);
    _timeout = timeout ?? const Duration(minutes: 1);
    if (savedData != null) {
      _accessToken = savedData["access_token"];
      // 注：ここでは、UNIXTimeに変換された時間が入っているため_updateJWTBuffは使えない。
      _accessTokenExpireUnixMS = savedData["access_token_expire_unix_ms"];
      _scope = savedData["scope"];
      _tokenType = savedData["token_type"];
      _refreshToken = savedData["refresh_token"];
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

  /// (en) Determines the sign-in state and notifies Stream of the current state.
  ///
  /// (ja) サインイン状態を判別して現在の状態をストリームに通知します。
  ///
  /// * [stream] : The auth stream.
  void updateStream(ROPCAuthStream stream) {
    if (_accessToken != null && !_isTokenExpired()) {
      stream.updateStream(EnumAuthStatus.signedIn);
    } else if (_refreshToken != null) {
      stream.updateStream(EnumAuthStatus.signedIn);
    } else {
      stream.updateStream(EnumAuthStatus.signedOut);
    }
  }

  /// (en) Returns whether the user is currently signed in.
  ///
  /// (ja) 現在サインイン状態かどうかを返します。
  bool isSignedIn() {
    if (_accessToken != null && !_isTokenExpired()) {
      return true;
    } else if (_refreshToken != null) {
      return true;
    } else {
      return false;
    }
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
  /// According to the OAuth2.0 specification,
  /// this will be sent as the username.
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
    final r = await UtilHttps.post(
        _registerUrl,
        {
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.scope: scope,
          FJsonKeysToServer.name: name,
          FJsonKeysToServer.nickname: nickname,
          FJsonKeysToServer.option: option
        },
        EnumPostEncodeType.json,
        timeout: _timeout,
        adjustTiming: false,
        charset: charset);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        try {
          // サーバーがトークンを返す仕様の場合は取得してログイン状態にする
          final Map<String, dynamic> tokens = jsonDecode(r.response!.body);
          _updateJWTBuff(tokens);
          return r;
        } catch (e) {
          // サーバーがトークンを返さない、または戻り値がJSONでは無いような場合。
          return r;
        }
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
        return r;
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
  /// According to the OAuth2.0 specification,
  /// this will be sent as the username.
  /// * [password] : pw.
  /// * [option] : Other optional parameters.
  Future<ServerResponse> deleteUser(String email, String password,
      {Map<String, dynamic>? option}) async {
    final r = await UtilHttps.post(
        _deleteUserURL,
        {
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.option: option
        },
        EnumPostEncodeType.json,
        timeout: _timeout,
        adjustTiming: false,
        charset: charset);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        _clearToken();
        return r;
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
        return r;
    }
  }

  /// 取得したトークンなどの情報をこのクラスに上書き保存します。
  /// 各パラメータのうちnullが渡されたものはクリア（nullで上書き）されます。
  ///
  /// * [tokens] : トークンデータが入った辞書。
  void _updateJWTBuff(Map<String, dynamic> tokens) {
    if (tokens.containsKey(FJsonKeysFromServer.accessToken)) {
      _accessToken = tokens[FJsonKeysFromServer.accessToken];
      _accessTokenExpireUnixMS = null;
      _scope = null;
      _tokenType = null;
    }
    if (tokens.containsKey(FJsonKeysFromServer.expiresIn)) {
      if (tokens[FJsonKeysFromServer.expiresIn] == null) {
        _accessTokenExpireUnixMS = null;
      } else {
        final int nowUnixTimeMS = DateTime.now().millisecondsSinceEpoch;
        _accessTokenExpireUnixMS = nowUnixTimeMS +
            (int.parse(tokens[FJsonKeysFromServer.expiresIn].toString()) *
                1000);
      }
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
    // コールバックがあれば起動する。
    if (updateJwtCallback != null) {
      updateJwtCallback!(toDict());
    }
  }

  /// (en) Obtain a token using
  /// the OAuth 2.0 "Resource Owner Password Credentials Grant" process.
  ///
  /// (ja) OAuth 2.0の「Resource Owner Password Credentials Grant」の処理で
  /// トークンを取得します。
  ///
  /// * [email] : User mail address. It is used as an ID(User name).
  /// According to the OAuth2.0 specification,
  /// this will be sent as the username.
  /// * [password] : pw.
  /// * [scope] : Application specific access permissions passed
  /// in space separated format, e.g. read write, user:follow, etc.
  Future<ServerResponse> signIn(String email, String password,
      {String? scope}) async {
    final r = await UtilHttps.post(
        _signInUrl,
        {
          FJsonKeysToServer.grantType: FGrantType.password,
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.scope: scope,
        },
        EnumPostEncodeType.urlEncoded,
        timeout: _timeout,
        adjustTiming: false,
        charset: charset);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        // トークンを取得して保存
        final Map<String, dynamic> tokens = jsonDecode(r.response!.body);
        _updateJWTBuff(tokens);
        // 必須パラメータの返却チェック
        if (_accessToken == null || _tokenType == null) {
          return UtilServerResponse.otherError(
              "OAuth 2.0 response error: missing token or token_type");
        }
        return r;
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
        return r;
    }
  }

  /// (en) Performs sign-out processing as specified in RFC 7009.
  /// This is a simplified version
  /// that invalidates the refresh token and access token in succession.
  /// If an error occurs along the way,
  /// an error status will simply be returned,
  /// which may make it difficult to understand the situation.
  /// To find out which token failed to be revoked when an error occurred,
  /// check the tokens held by the client.
  ///
  /// (ja) RFC 7009の仕様の通り、サインアウト処理を行います。
  /// これは簡易版で、リフレッシュトークンとアクセストークンを連続で失効処理します。
  /// 途中で何らかのエラーが発生した場合は、単にエラーステータスが返されます。
  /// エラー時にどのトークンの失効に失敗したのかを調べるには、
  /// クライアントの保持するトークンを確認してください。
  Future<ServerResponse> signOutAllTokens() async {
    ServerResponse res = await signOut(isRefreshToken: true);
    switch (res.resultStatus) {
      case EnumServerResponseStatus.success:
        return await signOut(isRefreshToken: false);
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
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
  Future<ServerResponse> signOut({required bool isRefreshToken}) async {
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
    final r = await UtilHttps.post(
        _revokeURL, target, EnumPostEncodeType.urlEncoded,
        timeout: _timeout, adjustTiming: false, charset: charset);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        if (isRefreshToken) {
          _updateJWTBuff({FJsonKeysFromServer.refreshToken: null});
        } else {
          _updateJWTBuff({
            FJsonKeysFromServer.accessToken: null,
            FJsonKeysFromServer.expiresIn: null,
            FJsonKeysFromServer.scope: null,
            FJsonKeysFromServer.tokenType: null,
          });
        }
        return r;
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
        return r;
    }
  }

  /// (en) Gets a JWT token.
  /// If the cached token has not yet expired, the cached token is returned.
  /// If the token has expired, an attempt is made to refresh
  /// it using the refresh token,
  /// but if that fails, null is returned.
  /// Also, null is returned if the user is not signed in.
  /// Debug builds only now display details when a token refresh fails.
  ///
  /// (ja) JWTトークンを取得します。
  /// キャッシュされたトークンの期限が残っている場合、キャッシュされたトークンが返されます。
  /// トークンが期限切れの場合はリフレッシュトークンを使ってリフレッシュを試みますが、
  /// 失敗した場合はnullを返します。
  /// また、サインイン状態では無い場合もnullが返されます。
  /// デバッグビルドでのみ、トークンのリフレッシュ失敗時に詳細が表示されます。
  Future<String?> getToken() async {
    if (_isTokenExpired()) {
      final ServerResponse res = await refreshAndGetNewToken();
      if (res.resultStatus != EnumServerResponseStatus.success) {
        if (kDebugMode) {
          debugPrint(res.errorDetail);
        }
        return null;
      }
    }
    return _accessToken;
  }

  /// トークンの期限切れをチェックします。
  bool _isTokenExpired() {
    if (_accessTokenExpireUnixMS == null) return true;
    return DateTime.now().millisecondsSinceEpoch >
        _accessTokenExpireUnixMS! - refreshMarginMs;
  }

  /// (en) This method should not be called directly except when debugging.
  /// Instead, use getToken.
  /// This uses the refresh token to obtain a new token and caches it.
  ///
  /// (ja) このメソッドは、通常は直接呼び出さないでください。
  /// 代わりに、getTokenを利用してください。
  /// これはリフレッシュトークンを使用して新しいトークンを取得し、キャッシュします。
  Future<ServerResponse> refreshAndGetNewToken() async {
    if (_refreshToken == null) {
      return UtilServerResponse.signInRequired();
    }
    final r = await UtilHttps.post(
        _refreshUrl,
        {
          FJsonKeysToServer.grantType: FGrantType.refreshToken,
          FJsonKeysToServer.refreshToken: _refreshToken,
        },
        EnumPostEncodeType.urlEncoded,
        timeout: _timeout,
        adjustTiming: false,
        charset: charset);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        try {
          // トークンを取得して保存
          final Map<String, dynamic> tokens = jsonDecode(r.response!.body);
          _updateJWTBuff(tokens);
          // 必須パラメータの返却チェック
          if (_accessToken == null || _tokenType == null) {
            return UtilServerResponse.otherError(
                "OAuth 2.0 response error: missing token or token_type");
          }
          return r;
        } catch (e) {
          return UtilServerResponse.otherError('Invalid token format');
        }
      case EnumServerResponseStatus.signInRequired:
        return UtilServerResponse.signInRequired(res: r.response);
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.otherError:
        return r;
    }
  }

  /// (en) Clear the local access and refresh tokens.
  /// Any additional information such as scope and deadlines
  /// will also be removed.
  ///
  /// (ja) ローカルのアクセストークン、及びリフレッシュトークンをクリアします。
  /// スコープや期限などの付加情報についてもクリアされます。
  void _clearToken() {
    _updateJWTBuff({
      FJsonKeysFromServer.accessToken: null,
      FJsonKeysFromServer.expiresIn: null,
      FJsonKeysFromServer.scope: null,
      FJsonKeysFromServer.tokenType: null,
      FJsonKeysFromServer.refreshToken: null
    });
  }
}
