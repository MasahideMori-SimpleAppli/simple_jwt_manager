/// サーバーへの送信時にJSONで利用されるキーを定義したクラス。
class FJsonKeysToServer {
  static String grantType = "grant_type";
  // これはOAuthの仕様上の名前であり、実際の内容にはemailが用いられる。
  static String username = "username";
  static String password = "password";
  // read writeや、user:followなど、アプリケーション固有の空文字区切りで渡されるアクセス権限。
  static String scope = "scope";
  // その他のセキュリティを高めるためのオプションパラメータを利用する場合に使用。
  static String option = "option";
  // 登録時オプションの本名。
  static String name = "name";
  // 登録時オプションのニックネーム。
  static String nickname = "nickname";
  // トークン類
  static String accessToken = "access_token";
  static String refreshToken = "refresh_token";
  static String tokenTypeHint = "token_type_hint";
}
