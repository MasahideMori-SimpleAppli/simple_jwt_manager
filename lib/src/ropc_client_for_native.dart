import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_jwt_manager/src/ropc_client_base.dart';
import 'package:simple_jwt_manager/src/ropc_config.dart';

/// (en) This class manages JWT tokens and controls login, as defined in
/// the Resource Owner Password Credentials Grant defined in RFC 6749.
/// This class is not available in Flutter web.
///
/// (ja) Resource Owner Password Credentials Grant defined in RFC 6749における、
/// JWTトークンの管理とログイン制御のためのクラスです。
/// このクラスはFlutter webでは利用できません。
///
/// Author Masahide Mori
///
/// First edition creation date 2024-11-17 20:31:04
class ROPCClientForNative extends ROPCClientBase {
  // static parameters
  static const String className = "ROPCClientForNative";
  static const int version = 9;

  // parameters
  final bool Function(X509Certificate cert, String host, int port)?
      _badCertificateCallback;
  final SecurityContext? _securityContext;
  final Duration _connectionTimeout;
  final Duration _responseTimeout;

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
  /// * [connectionTimeout] : Timeout period for server connection. Default is 10 sec.
  /// * [responseTimeout] : Timeout period for server response. Default is 1 min.
  /// * [charset] : Use this when you want to explicitly specify the charset in
  /// the HTTP header. If null, it will automatically be set to utf-8. Also,
  /// if you enter an empty string, no specification will be made.
  /// * [clientId] : The OAuth 2.0 client identifier (RFC 6749 Section 2.2).
  /// If set, it is sent as client_id with sign-in, refresh, and revocation
  /// (RFC 7009) requests. If null, client_id is not sent.
  /// * [badCertificateCallback] : A callback invoked when an invalid SSL certificate
  /// is encountered. Return `true` to accept the certificate (e.g., for self-signed
  /// certificates during local development), or `false` to reject it.
  /// CertificatePinner of simple_https_service can be used here.
  ///
  ///   **Warning:** Unconditionally returning `true` bypasses SSL verification and
  ///   introduces security risks in production environments.
  ///
  /// * [securityContext] : The SecurityContext used for TLS verification.
  /// If null, SecurityContext.defaultContext is used.
  /// To trust a self-signed certificate while keeping normal verification
  /// (including host name and expiry), use UtilSecurityContext of
  /// simple_https_service.
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
  ROPCClientForNative(
      {required super.registerURL,
      required super.signInURL,
      required super.refreshURL,
      required super.signOutURL,
      required super.deleteUserURL,
      Duration? connectionTimeout,
      Duration? responseTimeout,
      super.charset,
      super.clientId,
      bool Function(X509Certificate cert, String host, int port)?
          badCertificateCallback,
      SecurityContext? securityContext,
      super.savedData,
      super.refreshMarginMs,
      super.updateJwtCallback})
      : _badCertificateCallback = badCertificateCallback,
        _securityContext = securityContext,
        _connectionTimeout = connectionTimeout ?? const Duration(seconds: 10),
        _responseTimeout = responseTimeout ?? const Duration(minutes: 1);

  @override
  Map<String, dynamic> toDict() {
    return {
      "class_name": ROPCClientForNative.className,
      "version": ROPCClientForNative.version,
      ...tokenDict(),
    };
  }

  @override
  @protected
  Future<ServerResponse> postRequest(
      String url, Map<String, dynamic> body, EnumPostEncodeType type,
      {EnumServerResponseType resType = EnumServerResponseType.json}) {
    return HttpsServiceForNative.post(url, body, type,
        resType: resType,
        badCertificateCallback: _badCertificateCallback,
        securityContext: _securityContext,
        connectionTimeout: _connectionTimeout,
        responseTimeout: _responseTimeout,
        adjustTiming: false,
        charset: charset,
        retryIf: ROPCConfig().retryCondition,
        // retryIfがnullだとRetryConfigのdefaultConditionが使われるため、
        // ROPCConfigの仕様通りリトライしないよう、回数を0にする。
        maxRetries:
            ROPCConfig().retryCondition == null ? 0 : ROPCConfig().maxRetries,
        baseDelay: ROPCConfig().baseDelay,
        maxJitter: ROPCConfig().maxJitter);
  }
}
