/// サーバーからのデータ受信時にJSONで利用されるキーを定義したクラス。
class FJsonKeysFromServer {
  static const String accessToken = "access_token";
  static const String tokenType = "token_type";
  static const String expiresIn = "expires_in";
  static const String refreshToken = "refresh_token";
  // 要求したスコープと差異がある場合などに必要になる。
  static const String scope = "scope";
}
