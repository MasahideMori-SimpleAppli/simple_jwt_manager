import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_jwt_manager/src/ropc_token_buffer.dart';
import 'package:simple_jwt_manager/src/stream/enum_auth_status.dart';
import 'package:simple_jwt_manager/src/stream/ropc_auth_stream.dart';
import 'package:simple_jwt_manager/src/static_fields/f_grant_type.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_from_server.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_to_server.dart';
import 'package:simple_jwt_manager/src/util/util_oauth_error.dart';

/// (en) The common base class of ROPCClient and ROPCClientForNative.
/// It manages JWT tokens and controls login, as defined in
/// the Resource Owner Password Credentials Grant defined in RFC 6749,
/// and performs sign-out as defined in RFC 7009.
/// Subclasses only implement how requests are sent (postRequest) and
/// the saved data format (toDict).
///
/// (ja) ROPCClient及びROPCClientForNativeの共通基底クラスです。
/// RFC 6749のResource Owner Password Credentials Grantにおける
/// JWTトークンの管理とログイン制御、及びRFC 7009のサインアウトを行います。
/// サブクラスは、リクエストの送信方法（postRequest）と保存データの形式（toDict）のみを実装します。
///
/// Author Masahide Mori
///
/// First edition creation date 2026-11-02 00:00:00
abstract class ROPCClientBase {
  // parameters
  final String _registerUrl;
  final String _signInUrl;
  final String _refreshUrl;
  final String _revokeURL;
  final String _deleteUserURL;
  final int refreshMarginMs;
  final void Function(Map<String, dynamic> savedData)? updateJwtCallback;
  final String? charset;
  final String? clientId;

  // tokens
  final ROPCTokenBuffer _buff = ROPCTokenBuffer();

  /// (en) See the constructor of each subclass for details.
  /// If you pass a URL that does not start with HTTPS,
  /// an exception will be thrown.
  ///
  /// (ja) 詳細は各サブクラスのコンストラクタを参照してください。
  /// HTTPSから始まらないURLを渡した場合は例外がスローされます。
  ROPCClientBase(
      {required String registerURL,
      required String signInURL,
      required String refreshURL,
      required String signOutURL,
      required String deleteUserURL,
      this.charset,
      this.clientId,
      Map<String, dynamic>? savedData,
      this.refreshMarginMs = 30 * 1000,
      this.updateJwtCallback})
      : _registerUrl = UtilCheckURL.validateHttpsUrl(registerURL),
        _signInUrl = UtilCheckURL.validateHttpsUrl(signInURL),
        _refreshUrl = UtilCheckURL.validateHttpsUrl(refreshURL),
        _revokeURL = UtilCheckURL.validateHttpsUrl(signOutURL),
        _deleteUserURL = UtilCheckURL.validateHttpsUrl(deleteUserURL) {
    if (savedData != null) {
      _buff.restore(savedData);
    }
  }

  /// (en) Sends a POST request to the server.
  /// Implemented by each subclass using its own HTTPS service.
  ///
  /// (ja) サーバーにPOSTリクエストを送信します。
  /// 各サブクラスが、それぞれのHTTPSサービスを用いて実装します。
  ///
  /// * [url] : The destination URL.
  /// * [body] : The request body.
  /// * [type] : The encoding type of the body.
  /// * [resType] : Formatting the return value from the server.
  @protected
  Future<ServerResponse> postRequest(
      String url, Map<String, dynamic> body, EnumPostEncodeType type,
      {EnumServerResponseType resType = EnumServerResponseType.json});

  /// (en) Returns the token-related information held by
  /// this class in dictionary format.
  /// This can be used to store token information in your app, but
  /// you need to be careful about security.
  ///
  /// (ja) このクラスの保持するトークン関連情報を辞書形式で返します。
  /// これはアプリでのトークン情報を保存に利用できますが、
  /// セキュリティには気をつける必要があります。
  Map<String, dynamic> toDict();

  /// (en) Returns the token part of toDict. Used by subclasses.
  ///
  /// (ja) toDictのうち、トークン部分を返します。サブクラスから利用されます。
  @protected
  Map<String, dynamic> tokenDict() => _buff.toDict();

  /// (en) Determines the sign-in state and notifies Stream of the current state.
  ///
  /// (ja) サインイン状態を判別して現在の状態をストリームに通知します。
  ///
  /// * [stream] : The auth stream.
  /// * [forceSignOut] : If the status is signed out, the token cache managed
  /// by this class will be discarded.
  /// If this is true, the access token managed by the app will be discarded
  /// when this method is called, even if, for example, only the refresh token
  /// has been expired. However, the access token on the server side will not
  /// expire.
  void updateStream(ROPCAuthStream stream, {bool forceSignOut = false}) {
    if (isSignedIn()) {
      stream.updateStream(EnumAuthStatus.signedIn);
    } else {
      if (forceSignOut) {
        clearToken();
      }
      stream.updateStream(EnumAuthStatus.signedOut);
    }
  }

  /// (en) Returns whether the user is currently signed in.
  ///
  /// (ja) 現在サインイン状態かどうかを返します。
  bool isSignedIn() {
    return !_buff.isAccessTokenExpired(refreshMarginMs) ||
        _buff.refreshToken != null;
  }

  /// (en) Returns the refresh token.
  /// However, if the token has not yet been obtained, null is returned.
  ///
  /// (ja) 保持しているリフレッシュトークンを返します。
  /// ただし、まだ取得していない場合等はnullが返されます。
  String? getRefreshTokenBuff() => _buff.refreshToken;

  /// (en) Returns the access token.
  /// This should only be used to determine specific conditions,
  /// such as when sign-out has failed.
  ///
  /// (ja) 保持しているアクセストークンを返します。
  /// これはサインアウトに失敗した場合など、特定の状況を判定する場合にのみ使用してください。
  String? getAccessTokenBuff() => _buff.accessToken;

  /// (en) Returns the scope information of the held access token, if any.
  /// If the server omits scope, the requested scope is held, as specified in
  /// RFC 6749 Section 5.1. If neither is available, null is returned.
  ///
  /// (ja) 保持しているアクセストークンのスコープ情報があれば返します。
  /// サーバーがスコープを省略した場合は、RFC 6749 5.1節の通り、要求したスコープが保持されます。
  /// どちらも無い場合はnullが返されます。
  String? getAccessTokenScopeBuff() => _buff.scope;

  /// (en) Returns the type of the held access token, if any.
  ///
  /// (ja) 保持しているアクセストークンのタイプ情報があれば返します。
  String? getAccessTokenType() => _buff.tokenType;

  /// (en) This performs the user registration process.
  /// This process is not defined in OAuth2.0,
  /// so it must be implemented uniquely for your application.
  /// In the implementation of this package,
  /// information is POSTed in JSON to the registerUrl.
  /// The expected return from the server is JSON:
  /// {"access_token": String? token, "expires_in": int? sec,
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
  /// ｛"access_token": String? token, "expires_in": int? sec,
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
    final r = await postRequest(
        _registerUrl,
        {
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.scope: scope,
          FJsonKeysToServer.name: name,
          FJsonKeysToServer.nickname: nickname,
          FJsonKeysToServer.option: option
        },
        EnumPostEncodeType.json);
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
      case EnumServerResponseStatus.cancelled:
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
    final r = await postRequest(
        _deleteUserURL,
        {
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          FJsonKeysToServer.option: option
        },
        EnumPostEncodeType.json);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        clearToken();
        return r;
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
      case EnumServerResponseStatus.cancelled:
        return r;
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
    final r = await postRequest(
        _signInUrl,
        {
          FJsonKeysToServer.grantType: FGrantType.password,
          FJsonKeysToServer.username: email,
          FJsonKeysToServer.password: password,
          if (scope != null) FJsonKeysToServer.scope: scope,
          if (clientId != null) FJsonKeysToServer.clientId: clientId,
        },
        EnumPostEncodeType.urlEncoded);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        // RFC 6749 5.1: scopeが省略された場合は、要求したscopeと同一。
        return _storeTokenResponse(r, scope);
      case EnumServerResponseStatus.serverError:
        // RFC 6749 5.2: 認証情報の誤りは400 invalid_grantで返される。
        if (UtilOAuthError.isInvalidGrant(r)) {
          return UtilServerResponse.signInRequired(res: r.response);
        }
        return r;
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
      case EnumServerResponseStatus.cancelled:
        return r;
    }
  }

  /// (en) Performs sign-out processing as specified in RFC 7009.
  /// This will revoke the refresh token and the access token consecutively.
  /// A token that is not held by the client is not sent to the server and
  /// is treated as successfully revoked.
  /// If an error occurs along the way,
  /// an error status will simply be returned,
  /// which may make it difficult to understand the situation.
  /// To find out which token failed to be revoked when an error occurred,
  /// check the tokens held by the client.
  ///
  /// (ja) RFC 7009の仕様の通り、サインアウト処理を行います。
  /// これは、リフレッシュトークンとアクセストークンを連続で失効処理します。
  /// クライアントが保持していないトークンはサーバーに送信されず、失効成功として扱われます。
  /// 途中で何らかのエラーが発生した場合は、単にエラーステータスが返されます。
  /// エラー時にどのトークンの失効に失敗したのかを調べるには、
  /// クライアントの保持するトークンを確認してください。
  Future<ServerResponse> signOut() async {
    ServerResponse res = await revokeRefreshToken();
    switch (res.resultStatus) {
      case EnumServerResponseStatus.success:
        return await revokeAccessToken();
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.serverError:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.signInRequired:
      case EnumServerResponseStatus.cancelled:
        return res;
    }
  }

  /// (en) Performs access token sign-out processing as specified in RFC 7009.
  /// The response body is not parsed as JSON (RFC 7009 Section 2.2), and
  /// resBody contains it in the format { "r" : text }.
  /// If the client does not hold an access token, no request is sent,
  /// the related local information is cleared, and a success response
  /// with a null response and resBody is returned.
  ///
  /// (ja) RFC 7009の仕様の通り、アクセストークンのサインアウト処理を行います。
  /// レスポンスボディはJSONとして解析されず（RFC 7009 2.2節）、
  /// resBodyには { "r" : テキスト } の形式で格納されます。
  /// クライアントがアクセストークンを保持していない場合はリクエストを送信せず、
  /// 関連するローカル情報をクリアして、responseとresBodyがnullの成功レスポンスを返します。
  Future<ServerResponse> revokeAccessToken() async {
    final ServerResponse r =
        await _revoke(_buff.accessToken, FJsonKeysToServer.accessToken);
    if (r.resultStatus == EnumServerResponseStatus.success) {
      _buff.clearAccessToken();
      _notifyUpdate();
    }
    return r;
  }

  /// (en) Performs refresh token sign-out processing as specified in RFC 7009.
  /// The response body is not parsed as JSON (RFC 7009 Section 2.2), and
  /// resBody contains it in the format { "r" : text }.
  /// If the client does not hold a refresh token, no request is sent and
  /// a success response with a null response and resBody is returned.
  ///
  /// (ja) RFC 7009の仕様の通り、リフレッシュトークンのサインアウト処理を行います。
  /// レスポンスボディはJSONとして解析されず（RFC 7009 2.2節）、
  /// resBodyには { "r" : テキスト } の形式で格納されます。
  /// クライアントがリフレッシュトークンを保持していない場合はリクエストを送信せず、
  /// responseとresBodyがnullの成功レスポンスを返します。
  Future<ServerResponse> revokeRefreshToken() async {
    final ServerResponse r =
        await _revoke(_buff.refreshToken, FJsonKeysToServer.refreshToken);
    if (r.resultStatus == EnumServerResponseStatus.success &&
        _buff.refreshToken != null) {
      _updateJWTBuff({FJsonKeysFromServer.refreshToken: null});
    }
    return r;
  }

  /// RFC 7009の失効リクエストを送信します。
  /// tokenがnullの場合は送信せず、responseとresBodyがnullの成功レスポンスを返します。
  /// 保持情報の更新は呼び出し元で行います。
  ///
  /// * [token] : 失効させるトークン。
  /// * [tokenTypeHint] : トークンの種類。FJsonKeysToServerのaccessTokenかrefreshToken。
  Future<ServerResponse> _revoke(String? token, String tokenTypeHint) async {
    if (token == null) {
      return ServerResponse(null, EnumServerResponseStatus.success, null, null);
    }
    return postRequest(
        _revokeURL,
        {
          FJsonKeysToServer.token: token,
          FJsonKeysToServer.tokenTypeHint: tokenTypeHint,
          if (clientId != null) FJsonKeysToServer.clientId: clientId,
        },
        EnumPostEncodeType.urlEncoded,
        resType: EnumServerResponseType.text);
  }

  /// (en) Gets a JWT token.
  /// If the cached token has not yet expired, the cached token is returned.
  /// If the token has expired, an attempt is made to refresh
  /// it using the refresh token,
  /// but if that fails, null is returned.
  /// Also, null is returned if the user is not signed in.
  /// If the server does not return expires_in, the access token is treated
  /// as valid. In that case, call refreshAndGetNewToken when
  /// a resource server rejects the token (e.g. HTTP 401).
  /// Debug builds only now display details when a token refresh fails.
  ///
  /// (ja) JWTトークンを取得します。
  /// キャッシュされたトークンの期限が残っている場合、キャッシュされたトークンが返されます。
  /// トークンが期限切れの場合はリフレッシュトークンを使ってリフレッシュを試みますが、
  /// 失敗した場合はnullを返します。
  /// また、サインイン状態では無い場合もnullが返されます。
  /// サーバーがexpires_inを返さない場合、アクセストークンは有効とみなされます。
  /// その場合は、リソースサーバーにトークンを拒否されたとき（HTTP 401など）に
  /// refreshAndGetNewTokenを呼び出してください。
  /// デバッグビルドでのみ、トークンのリフレッシュ失敗時に詳細が表示されます。
  Future<String?> getToken() async {
    if (_buff.isAccessTokenExpired(refreshMarginMs)) {
      final ServerResponse res = await refreshAndGetNewToken();
      if (res.resultStatus != EnumServerResponseStatus.success) {
        if (kDebugMode) {
          debugPrint(res.errorDetail);
        }
        return null;
      }
    }
    return _buff.accessToken;
  }

  /// (en) This method should not be called directly except when debugging.
  /// Instead, use getToken.
  /// The exception is when the server does not return expires_in
  /// (see getToken).
  /// This uses the refresh token to obtain a new token and caches it.
  ///
  /// (ja) このメソッドは、通常は直接呼び出さないでください。
  /// 代わりに、getTokenを利用してください。
  /// 例外は、サーバーがexpires_inを返さない場合です（getTokenを参照）。
  /// これはリフレッシュトークンを使用して新しいトークンを取得し、キャッシュします。
  Future<ServerResponse> refreshAndGetNewToken() async {
    if (_buff.refreshToken == null) {
      clearToken();
      return UtilServerResponse.signInRequired();
    }
    final r = await postRequest(
        _refreshUrl,
        {
          FJsonKeysToServer.grantType: FGrantType.refreshToken,
          FJsonKeysToServer.refreshToken: _buff.refreshToken,
          if (clientId != null) FJsonKeysToServer.clientId: clientId,
        },
        EnumPostEncodeType.urlEncoded);
    switch (r.resultStatus) {
      case EnumServerResponseStatus.success:
        // RFC 6749 6: scopeが省略された場合は、元のscopeと同一。
        return _storeTokenResponse(r, _buff.scope);
      case EnumServerResponseStatus.signInRequired:
        clearToken();
        return UtilServerResponse.signInRequired(res: r.response);
      case EnumServerResponseStatus.serverError:
        // RFC 6749 5.2: リフレッシュトークンの期限切れや失効は400 invalid_grantで返される。
        if (UtilOAuthError.isInvalidGrant(r)) {
          clearToken();
          return UtilServerResponse.signInRequired(res: r.response);
        }
        return r;
      case EnumServerResponseStatus.timeout:
      case EnumServerResponseStatus.otherError:
      case EnumServerResponseStatus.cancelled:
        return r;
    }
  }

  /// トークンエンドポイントの成功レスポンス（RFC 6749 5.1）を解析して保持します。
  /// 必須のaccess_tokenとtoken_typeが無い場合や、解析できない場合はotherErrorを返します。
  ///
  /// * [r] : トークンエンドポイントからの成功レスポンス。
  /// * [defaultScope] : レスポンスがscopeを省略した場合に保持するスコープ。
  ServerResponse _storeTokenResponse(ServerResponse r, String? defaultScope) {
    try {
      final Map<String, dynamic> tokens = jsonDecode(r.response!.body);
      if (!tokens.containsKey(FJsonKeysFromServer.scope)) {
        tokens[FJsonKeysFromServer.scope] = defaultScope;
      }
      _updateJWTBuff(tokens);
      // 必須パラメータの返却チェック
      if (_buff.accessToken == null || _buff.tokenType == null) {
        return UtilServerResponse.otherError(
            "OAuth 2.0 response error: missing token or token_type");
      }
      return r;
    } catch (e) {
      return UtilServerResponse.otherError('Invalid token format');
    }
  }

  /// 取得したトークンなどの情報で保持情報を上書きし、更新を通知します。
  /// 各パラメータのうちnullが渡されたものはクリア（nullで上書き）されます。
  ///
  /// * [tokens] : トークンデータが入った辞書。
  void _updateJWTBuff(Map<String, dynamic> tokens) {
    _buff.update(tokens);
    _notifyUpdate();
  }

  /// updateJwtCallbackがあれば、現在のtoDictの結果を渡して呼び出します。
  void _notifyUpdate() {
    updateJwtCallback?.call(toDict());
  }

  /// (en) Clears the access token and refresh token managed by this class.
  /// Any additional information such as scope and deadlines
  /// will also be removed.
  ///
  /// (ja) このクラスで管理しているアクセストークン、及びリフレッシュトークンをクリアします。
  /// スコープや期限などの付加情報についてもクリアされます。
  void clearToken() {
    _buff.clear();
    _notifyUpdate();
  }
}
