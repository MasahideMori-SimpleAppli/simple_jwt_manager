/// サーバーへの送信時にJSONで利用されるキーを定義したクラス。
class FJsonKeysToServer {
  static const String grantType = "grant_type";
  // これはOAuthの仕様上の名前であり、実際の内容にはemailが用いられる。
  static const String username = "username";
  static const String password = "password";
  // read writeや、user:followなど、アプリケーション固有の空文字区切りで渡されるアクセス権限。
  static const String scope = "scope";
  // その他のセキュリティを高めるためのオプションパラメータを利用する場合に使用。
  static const String option = "option";
  // 登録時オプションの本名。
  static const String name = "name";
  // 登録時オプションのニックネーム。
  static const String nickname = "nickname";
  // トークン類
  static const String accessToken = "access_token";
  static const String refreshToken = "refresh_token";
  static const String tokenTypeHint = "token_type_hint";
}
