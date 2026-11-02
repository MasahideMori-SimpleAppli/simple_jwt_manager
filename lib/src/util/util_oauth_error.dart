import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_jwt_manager/src/static_fields/f_json_keys_from_server.dart';

/// (en) Utility for interpreting OAuth 2.0 error responses
/// defined in RFC 6749 Section 5.2.
///
/// (ja) RFC 6749 5.2節で定義される、OAuth 2.0のエラーレスポンスを判定するユーティリティです。
///
/// Author Masahide Mori
///
/// First edition creation date 2026-11-02 00:00:00
class UtilOAuthError {
  /// RFC 6749 5.2節のエラーコード。認証情報やリフレッシュトークンが無効な場合に返される。
  static const String invalidGrant = "invalid_grant";

  /// (en) Returns true if [res] is an HTTP 400 response whose error is
  /// "invalid_grant". The server returns this when the resource owner
  /// credentials or the refresh token are invalid, expired, or revoked.
  ///
  /// (ja) [res] が、errorが"invalid_grant"であるHTTP 400のレスポンスであればtrueを返します。
  /// これは、ユーザーの認証情報やリフレッシュトークンが無効、期限切れ、
  /// または失効済みの場合にサーバーから返されます。
  ///
  /// * [res] : The server response from the token endpoint.
  static bool isInvalidGrant(ServerResponse res) {
    return res.resultStatus == EnumServerResponseStatus.serverError &&
        res.response?.statusCode == 400 &&
        res.resBody?[FJsonKeysFromServer.error] == invalidGrant;
  }
}
