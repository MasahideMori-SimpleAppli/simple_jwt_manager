/// (en) To simplify responses from the server,
/// This is an enum that classifies the response content into
/// five types:
/// successful processing, timeout, server error,
/// other error (including communication error), SignIn required.
///
/// (ja) サーバーからの応答を単純化するために、
/// 応答内容を処理成功、タイムアウト、サーバーエラー、その他のエラー（通信エラーを含む）、
/// 要signInの５種類に分類するためのenumです。
///
/// Author Masahide Mori
///
/// First edition creation date 2024-10-29 17:34:13
enum EnumSeverResponseStatus {
  success,
  timeout,
  serverError,
  otherError,
  signInRequired,
}
