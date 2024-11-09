/// サーバーへの送信時にJSONで利用されるキーを定義したクラス。
class FJsonKeysToServer{
  static String grantType = "grant_type";
  // これはOAuthの仕様上の名前であり、実際の内容にはemailが用いられる。
  static String username = "username";
  static String password = "password";
  static String clientID = "client_id";
  static String clientSecret = "client_secret";
  // 登録時オプションの本名。
  static String name = "name";
  // 登録時オプションのニックネーム。
  static String nickname = "nickname";
  static String refreshToken = "refresh_token";
  static String tokenTypeHint = "token_type_hint";
}