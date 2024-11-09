# simple_jwt_manager

## 注意
現在、本ソフトウェアは開発中です。  
この注意書きが削除されるまでは使用できないことに注意してください。  

## 概要
これは、[RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3)で定義されている、  
「Resource Owner Password Credentials Grant」を用いた認証をサポートするためのパッケージです。
メモリ上でのトークンの管理や、認証のためのエンドポイントへのアクセスなどをサポートします。

## 使い方
pub.devのExampleタブをチェックしてください。

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

## 著作権表示
The “Dart” name and “Flutter” name are trademarks of Google LLC.  
*The developer of this package is not Google LLC.