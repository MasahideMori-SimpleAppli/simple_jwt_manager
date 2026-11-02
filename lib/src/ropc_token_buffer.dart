import 'package:simple_jwt_manager/src/static_fields/f_json_keys_from_server.dart';

/// (en) A class that holds the tokens obtained from the server and
/// their related information (expiration, scope, token type).
/// It has no communication function and is used internally by
/// ROPCClient and ROPCClientForNative.
///
/// (ja) サーバーから取得したトークンと、その付加情報（期限、スコープ、トークンタイプ）を
/// 保持するクラスです。通信機能は持たず、ROPCClient及びROPCClientForNativeの内部で利用されます。
///
/// Author Masahide Mori
///
/// First edition creation date 2026-11-02 00:00:00
class ROPCTokenBuffer {
  String? _accessToken;
  String? _refreshToken;
  int? _accessTokenExpireUnixMS;
  String? _scope;
  String? _tokenType;

  /// (en) The held access token. null if not held.
  ///
  /// (ja) 保持しているアクセストークン。保持していない場合はnull。
  String? get accessToken => _accessToken;

  /// (en) The held refresh token. null if not held.
  ///
  /// (ja) 保持しているリフレッシュトークン。保持していない場合はnull。
  String? get refreshToken => _refreshToken;

  /// (en) The scope of the held access token. null if unknown.
  ///
  /// (ja) 保持しているアクセストークンのスコープ。不明な場合はnull。
  String? get scope => _scope;

  /// (en) The type of the held access token (e.g. Bearer). null if not held.
  ///
  /// (ja) 保持しているアクセストークンのタイプ（Bearerなど）。保持していない場合はnull。
  String? get tokenType => _tokenType;

  /// (en) Restores the tokens from the data created by toDict.
  ///
  /// (ja) toDictで作成されたデータからトークンを復元します。
  ///
  /// * [savedData] : The data created by toDict.
  void restore(Map<String, dynamic> savedData) {
    _accessToken = savedData["access_token"];
    // 注：ここでは、UNIXTimeに変換された時間が入っているためupdateは使えない。
    _accessTokenExpireUnixMS = savedData["access_token_expire_unix_ms"];
    _scope = savedData["scope"];
    _tokenType = savedData["token_type"];
    _refreshToken = savedData["refresh_token"];
  }

  /// (en) Returns the held tokens and related information
  /// in dictionary format for saving.
  ///
  /// (ja) 保持しているトークンと付加情報を、保存用の辞書形式で返します。
  Map<String, dynamic> toDict() {
    return {
      "access_token": _accessToken,
      "access_token_expire_unix_ms": _accessTokenExpireUnixMS,
      "scope": _scope,
      "token_type": _tokenType,
      "refresh_token": _refreshToken,
    };
  }

  /// (en) Overwrites the held information with a token response from the server.
  /// Only the keys contained in [tokens] are updated, and a key with
  /// a null value is cleared. If access_token is contained, the expiration,
  /// scope, and token type are reset before being updated.
  /// expires_in (seconds) is accepted as an integer, a decimal number,
  /// or a numeric string. If it cannot be parsed, an exception is thrown
  /// without changing the held information.
  ///
  /// (ja) サーバーからのトークンレスポンスで保持情報を上書きします。
  /// [tokens] に含まれるキーのみ更新され、値がnullのキーはクリアされます。
  /// access_tokenが含まれる場合、期限、スコープ、トークンタイプは一度リセットされてから更新されます。
  /// expires_in（秒）は整数、小数、数値の文字列を受け付けます。
  /// 解析できない場合は、保持情報を変更せずに例外がスローされます。
  ///
  /// * [tokens] : The token response from the server.
  void update(Map<String, dynamic> tokens) {
    // 解析失敗の例外で途中まで更新された状態にならないよう、期限は先に計算する。
    final Object? expiresIn = tokens[FJsonKeysFromServer.expiresIn];
    final int? expireUnixMS = expiresIn == null
        ? null
        : DateTime.now().millisecondsSinceEpoch +
            (num.parse(expiresIn.toString()) * 1000).round();
    if (tokens.containsKey(FJsonKeysFromServer.accessToken)) {
      _accessToken = tokens[FJsonKeysFromServer.accessToken];
      _accessTokenExpireUnixMS = null;
      _scope = null;
      _tokenType = null;
    }
    if (tokens.containsKey(FJsonKeysFromServer.expiresIn)) {
      _accessTokenExpireUnixMS = expireUnixMS;
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

  /// (en) Returns whether the access token has expired
  /// (or will expire within [marginMs]).
  /// Returns true if no access token is held.
  /// If the expiration is unknown because the server did not return
  /// expires_in, the token is treated as valid and false is returned,
  /// since expires_in is optional in RFC 6749 Section 5.1.
  ///
  /// (ja) アクセストークンが期限切れ（または [marginMs] 以内に期限切れ）かどうかを返します。
  /// アクセストークンが無い場合はtrueを返します。
  /// サーバーがexpires_inを返さず期限が不明な場合は、RFC 6749 5.1節で
  /// expires_inが任意であることから、有効とみなしてfalseを返します。
  ///
  /// * [marginMs] : The margin to estimate the expiration early.
  bool isAccessTokenExpired(int marginMs) {
    if (_accessToken == null) return true;
    if (_accessTokenExpireUnixMS == null) return false;
    return DateTime.now().millisecondsSinceEpoch >
        _accessTokenExpireUnixMS! - marginMs;
  }

  /// (en) Clears the access token and its related information
  /// (expiration, scope, token type). The refresh token is kept.
  ///
  /// (ja) アクセストークンと、その付加情報（期限、スコープ、トークンタイプ）をクリアします。
  /// リフレッシュトークンは保持されたままです。
  void clearAccessToken() {
    update({
      FJsonKeysFromServer.accessToken: null,
      FJsonKeysFromServer.expiresIn: null,
      FJsonKeysFromServer.scope: null,
      FJsonKeysFromServer.tokenType: null,
    });
  }

  /// (en) Clears all held tokens and related information.
  ///
  /// (ja) 保持している全てのトークンと付加情報をクリアします。
  void clear() {
    clearAccessToken();
    update({FJsonKeysFromServer.refreshToken: null});
  }
}
