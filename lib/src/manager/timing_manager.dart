/// (en) A manager that allows you to adjust timing when POSTing via https, etc.
/// This can be useful, for example,
/// when there is a write limit (x items/second) on the backend.
/// This works with singletons.
///
/// (ja) HttpsでPOSTするとき等に、タイミング調整を可能にするためのマネージャー。
/// 例えばバックエンドに書き込み制限（x件/秒）などがある場合に活用できます。
/// これはシングルトンで動作します。
class TimingManager {
  static final TimingManager _instance = TimingManager._internal();

  TimingManager._internal();

  /// Singleton manager class.
  factory TimingManager() {
    return _instance;
  }

  /// Last access UNIX time (milliseconds).
  int _lastAccessUnixMs = 0;

  /// (em) This method can be called with await to adjust
  /// the program execution interval.
  ///
  /// (ja) await付きで呼び出すことで、プログラムの実行間隔を調整するためのメソッドです。
  ///
  /// * [intervalMs] : Specifies how many milliseconds must elapse before
  /// the next execution can occur.
  /// When you call this consecutively,
  /// it is guaranteed to wait the specified number of milliseconds.
  /// By default it will wait 1200 milliseconds.
  Future<void> adjustTiming({int intervalMs = 1200}) {
    int nowAccessUnixMs = DateTime.now().millisecondsSinceEpoch;
    if ((_lastAccessUnixMs + intervalMs) < nowAccessUnixMs) {
      _lastAccessUnixMs = nowAccessUnixMs;
    } else {
      _lastAccessUnixMs = _lastAccessUnixMs + intervalMs;
    }
    final int delayTimeMs = _lastAccessUnixMs - nowAccessUnixMs;
    if (delayTimeMs > 0) {
      return Future.delayed(Duration(milliseconds: delayTimeMs), () {
        return null;
      });
    } else {
      return Future(() {
        return null;
      });
    }
  }
}
