/// サーバーからのデータ受信時にJSONで利用されるキーを定義したクラス。
class FJsonKeysFromServer{
  static String accessToken = "access_token";
  static String tokenType = "token_type";
  static String expiresIn = "expires_in";
  static String refreshToken = "refresh_token";
  // 要求したスコープと差異がある場合などに必要になる。
  static String scope = "scope";
}