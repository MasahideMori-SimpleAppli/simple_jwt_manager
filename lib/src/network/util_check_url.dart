/// (en) A utility for checking communication security.
///
/// (ja) 通信のセキュリティチェック用のユーティリティです。
///
/// /// Author Masahide Mori
///
/// First edition creation date 2024-11-09 20:59:07
class UtilCheckURL {
  /// (en) If the specified URL is not HTTP, an exception will be thrown.
  /// Otherwise the value is returned unchanged.
  ///
  /// (ja) 指定したURLがhttpでは無かった場合、例外をスローします。
  /// それ以外の場合はそのままの値が返されます。
  ///
  /// * [url] : Target url.
  static String validateHttpsUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') {
      throw Exception('URL must use HTTPS. Invalid URL: $url');
    }
    return url;
  }
}
