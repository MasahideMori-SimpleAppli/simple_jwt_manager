import 'dart:async';
import 'package:simple_jwt_manager/src/stream/enum_auth_status.dart';

/// (en) A stream for managing the sign-in and sign-out states.
///
/// (ja) サインイン及びサインアウト状態を管理するためのストリームです。
class ROPCAuthStream {
  final _ctrl = StreamController<EnumAuthStatus>.broadcast();

  ROPCAuthStream() {
    updateStream(EnumAuthStatus.unknown);
  }

  /// (en) Gets a stream.
  ///
  /// (ja) ストリームを取得します。
  Stream<EnumAuthStatus> getStream() {
    return _ctrl.stream;
  }

  /// (en) Update the stream.
  ///
  /// (ja) ストリームをアップデートします。
  /// * [value] : The updated value of the stream.
  void updateStream(EnumAuthStatus value) {
    _ctrl.add(value);
  }

  /// (en) Closes the stream.
  /// There is no need to call this if there is only one this object in the entire app.
  /// Once this method is called, the object is no longer available.
  ///
  /// (ja) ストリームを閉じます。
  /// アプリ全体で１つだけこのオブジェクトを持っているような場合には呼び出しは不要です。
  /// このメソッドが呼び出されると、このオブジェクトは利用できなくなります。
  void dispose() {
    _ctrl.close();
  }
}
