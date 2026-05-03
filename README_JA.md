# simple_jwt_manager

(en)English ver is [here](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README.md).  
(ja)この解説の英語版は[ここ](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README.md)にあります。

## 概要
これは、JWTを用いた認証をサポートするためのパッケージです。  
[RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3)で定義されている
「Resource Owner Password Credentials Grant」を用いた認証や、一般的なユーザー登録等をサポートしています。  
サインアウト処理は [RFC 7009](https://datatracker.ietf.org/doc/html/rfc7009)に従います。

## パッケージ構成

v2.0.0以降、ネットワーク機能は `simple_https_service` に分離されました。

| パッケージ | 役割 |
|---|---|
| `simple_jwt_manager` | ROPC認証とJWTトークン管理 |
| [`simple_https_service`](https://pub.dev/packages/simple_https_service) | HTTPS通信・リトライ・タイミング制御 |

`pubspec.yaml` に両方を追加してください：

```yaml
dependencies:
  simple_jwt_manager: ^2.0.0
  simple_https_service: ^1.0.0
```

エラー報告が必要な場合は [`simple_error_reporter`](https://pub.dev/packages/simple_error_reporter) を別途追加してください。

## 機能
- ユーザー登録、サインイン、サインアウト、アカウント削除
- リフレッシュトークンを使ったアクセストークンの自動更新
- `toDict()` / `savedData` によるトークンの永続化サポート
- トークン変更時にローカル保存処理を自動実行する `updateJwtCallback`
- GoRouterなどと組み合わせて使えるストリームベースのサインイン状態管理（`ROPCAuthStream`）
- パッケージごとに独立したリトライ制御のための `ROPCConfig` シングルトン

2つの実装が用意されています：
- `ROPCClient`: WebとNativeの両プラットフォームで動作します。
- `ROPCClientForNative`: Native専用で、`badCertificateCallback`による自己署名証明書のサポートがあります。

## 使い方

### 基本的なセットアップ

```dart
import 'package:simple_jwt_manager/simple_jwt_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ropcClient = ROPCClient(
    registerURL: 'https://your-endpoint.example.com/register',
    signInURL: 'https://your-endpoint.example.com/sign-in',
    refreshURL: 'https://your-endpoint.example.com/refresh',
    signOutURL: 'https://your-endpoint.example.com/sign-out',
    deleteUserURL: 'https://your-endpoint.example.com/delete-user',
    updateJwtCallback: (savedData) async {
      // トークンが変更または削除されるたびに呼び出されます。
      // ここでローカルストレージへの保存や削除処理を行ってください。
    },
  );

  runApp(const MyApp());
}
```

### サインインとサインアウト

```dart
// サインイン
final res = await ropcClient.signIn(email, password);
switch (res.resultStatus) {
  case EnumServerResponseStatus.success:
    // サインイン成功。
  case EnumServerResponseStatus.signInRequired:
    // 認証情報が正しくありません。
  default:
    // タイムアウト・サーバーエラー・その他のエラーを処理。
}

// サインアウト
await ropcClient.signOut();
```

### 認証付きリクエスト

現在のアクセストークンを取得して `HttpsService` に渡します：

```dart
import 'package:simple_https_service/simple_https_service.dart';

final jwt = await ropcClient.getToken();
if (jwt != null) {
  final res = await HttpsService.post(
    url, body, EnumPostEncodeType.json, jwt: jwt,
  );
}
```

### トークンの永続化

```dart
// 現在のトークン状態をシリアライズして保存:
final Map<String, dynamic> savedData = ropcClient.toDict();

// 次回起動時に復元:
final ropcClient = ROPCClient(
  ...,
  savedData: savedData,
);
```

### ストリームによる状態管理（GoRouter等との連携）

```dart
final authStream = ROPCAuthStream();

authStream.getStream().listen((EnumAuthStatus status) {
  // ステータスに応じてナビゲート。
});

// サインイン・サインアウト後にストリームを更新:
ropcClient.updateStream(authStream);
```

### リトライの設定

デフォルトでは、すべてのHTTP通信はリトライなしで1回だけ送信されます。  
`ROPCConfig` を使うと、`simple_https_service` のグローバルなリトライ設定に影響を与えずに、JWTマネージャー独自のリトライ動作を設定できます。

```dart
// ROPCClient を作成する前、例えば main() 内で設定。
ROPCConfig().maxRetries = 3;
ROPCConfig().baseDelay = const Duration(seconds: 1);
ROPCConfig().maxJitter = const Duration(milliseconds: 500);
ROPCConfig().retryCondition = (url, res, error) {
  return res.resultStatus == EnumServerResponseStatus.serverError ||
      error != null;
};
```

`retryCondition` が設定されていない場合（`null`）、`maxRetries` の値に関わらずリトライは行われません。グローバルな `RetryConfig` の設定も影響しません。

## サポート
基本的にサポートはありません。  
もし問題がある場合はGithubのissueを開いてください。  
このパッケージは優先度が低いですが、修正される可能性があります。

## バージョン管理について
それぞれ、Cの部分が変更されます。  
ただし、バージョン1.0.0未満は以下のルールに関係無くファイル構造が変化する場合があります。  
- 変数の追加など、以前のファイルの読み込み時に問題が起こったり、ファイルの構造が変わるような変更
  - C.X.X
- メソッドの追加など
  - X.C.X
- 軽微な変更やバグ修正
  - X.X.C

## ライセンス
このソフトウェアはApache-2.0ライセンスの元配布されます。LICENSEファイルの内容をご覧ください。

Copyright 2024-2026 Masahide Mori

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Trademarks

- "Dart" および "Flutter" は Google LLC の商標です。  
  *このパッケージは Google LLC によって開発・推奨されたものではありません。*
