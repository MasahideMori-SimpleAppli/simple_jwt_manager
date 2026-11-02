import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';

/// サインイン後にサインアウトし、失効URLへ送られたリクエストボディを順に返します。
/// 失効レスポンスは RFC 7009 の典型例として、空ボディの200を返します。
Future<List<String>> _signInAndSignOut({String? clientId}) async {
  const String revokeURL = 'https://example.com/revoke';
  final List<String> revokeBodies = [];
  final client = MockClient((req) async {
    if (req.url.toString() == revokeURL) {
      revokeBodies.add(req.body);
      return http.Response('', 200);
    }
    return http.Response(
        jsonEncode({
          'access_token': 'AT',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': 'RT',
        }),
        200);
  });
  await http.runWithClient(() async {
    final ropc = ROPCClient(
        registerURL: 'https://example.com/register',
        signInURL: 'https://example.com/sign-in',
        refreshURL: 'https://example.com/refresh',
        signOutURL: revokeURL,
        deleteUserURL: 'https://example.com/delete',
        clientId: clientId);
    await ropc.signIn('a@example.com', 'pw');
    final res = await ropc.signOut();
    expect(res.resultStatus, EnumServerResponseStatus.success);
  }, () => client);
  return revokeBodies;
}

void main() {
  group('RFC 7009 revocation request', () {
    test('sends token, token_type_hint and client_id', () async {
      final bodies = await _signInAndSignOut(clientId: 'cid');
      expect(bodies, [
        'token=RT&token_type_hint=refresh_token&client_id=cid',
        'token=AT&token_type_hint=access_token&client_id=cid',
      ]);
    });

    test('omits client_id when clientId is null', () async {
      final bodies = await _signInAndSignOut();
      expect(bodies, [
        'token=RT&token_type_hint=refresh_token',
        'token=AT&token_type_hint=access_token',
      ]);
    });
  });

  group('RFC 6749 invalid_grant', () {
    final http.Response invalidGrant =
        http.Response(jsonEncode({'error': 'invalid_grant'}), 400);
    ROPCClient newClient() => ROPCClient(
        registerURL: 'https://example.com/register',
        signInURL: 'https://example.com/sign-in',
        refreshURL: 'https://example.com/refresh',
        signOutURL: 'https://example.com/revoke',
        deleteUserURL: 'https://example.com/delete');

    test('sign-in with wrong credentials returns signInRequired', () async {
      await http.runWithClient(() async {
        final res = await newClient().signIn('a@example.com', 'wrong');
        expect(res.resultStatus, EnumServerResponseStatus.signInRequired);
      }, () => MockClient((req) async => invalidGrant));
    });

    test('refresh with invalid refresh token clears tokens', () async {
      await http.runWithClient(() async {
        final ropc = newClient();
        await ropc.signIn('a@example.com', 'pw');
        final res = await ropc.refreshAndGetNewToken();
        expect(res.resultStatus, EnumServerResponseStatus.signInRequired);
        expect(ropc.isSignedIn(), isFalse);
      },
          () => MockClient((req) async => req.url.path == '/refresh'
              ? invalidGrant
              : http.Response(
                  jsonEncode({
                    'access_token': 'AT',
                    'token_type': 'Bearer',
                    'refresh_token': 'RT',
                  }),
                  200)));
    });
  });

  group('Subclass construction', () {
    const Map<String, dynamic> saved = {
      'access_token': 'AT',
      'access_token_expire_unix_ms': 123,
      'scope': 'read',
      'token_type': 'Bearer',
      'refresh_token': 'RT',
    };
    final ropc = ROPCClient(
        registerURL: 'https://example.com/register',
        signInURL: 'https://example.com/sign-in',
        refreshURL: 'https://example.com/refresh',
        signOutURL: 'https://example.com/revoke',
        deleteUserURL: 'https://example.com/delete',
        savedData: saved);
    final native = ROPCClientForNative(
        registerURL: 'https://example.com/register',
        signInURL: 'https://example.com/sign-in',
        refreshURL: 'https://example.com/refresh',
        signOutURL: 'https://example.com/revoke',
        deleteUserURL: 'https://example.com/delete',
        savedData: saved);

    test('inherits default refreshMarginMs via super parameter', () {
      expect(ropc.refreshMarginMs, 30 * 1000);
      expect(native.refreshMarginMs, 30 * 1000);
    });

    test('toDict keeps class info and restores savedData', () {
      expect(
          ropc.toDict(), {'class_name': 'ROPCClient', 'version': 11, ...saved});
      expect(native.toDict(),
          {'class_name': 'ROPCClientForNative', 'version': 9, ...saved});
    });
  });

  group('ROPCConfig', () {
    setUp(() {
      ROPCConfig().maxRetries = 0;
      ROPCConfig().baseDelay = const Duration(seconds: 1);
      ROPCConfig().maxJitter = const Duration(milliseconds: 500);
      ROPCConfig().retryCondition = null;
    });

    test('null retryCondition ignores global RetryConfig', () async {
      ROPCConfig()
        ..maxRetries = 3
        ..baseDelay = Duration.zero
        ..maxJitter = Duration.zero;
      RetryConfig().defaultCondition = (url, res, error) => true;
      addTearDown(() => RetryConfig().defaultCondition = null);
      int count = 0;
      await http.runWithClient(() async {
        await ROPCClient(
                registerURL: 'https://example.com/register',
                signInURL: 'https://example.com/sign-in',
                refreshURL: 'https://example.com/refresh',
                signOutURL: 'https://example.com/revoke',
                deleteUserURL: 'https://example.com/delete')
            .signIn('a@example.com', 'pw');
      },
          () => MockClient((req) async {
                count++;
                return http.Response('', 500);
              }));
      expect(count, 1);
    });

    test('is singleton', () {
      final a = ROPCConfig();
      final b = ROPCConfig();
      expect(identical(a, b), isTrue);
    });

    test('defaults to no retries', () {
      expect(ROPCConfig().maxRetries, 0);
    });

    test('default baseDelay is 1 second', () {
      expect(ROPCConfig().baseDelay, const Duration(seconds: 1));
    });

    test('default maxJitter is 500 milliseconds', () {
      expect(ROPCConfig().maxJitter, const Duration(milliseconds: 500));
    });

    test('default retryCondition is null', () {
      expect(ROPCConfig().retryCondition, isNull);
    });

    test('can update maxRetries', () {
      ROPCConfig().maxRetries = 3;
      expect(ROPCConfig().maxRetries, 3);
    });

    test('can set retryCondition', () {
      bool called = false;
      ROPCConfig().retryCondition = (url, res, error) {
        called = true;
        return false;
      };
      ROPCConfig().retryCondition!(
          'https://example.com',
          ServerResponse(null, EnumServerResponseStatus.otherError, null, null),
          null);
      expect(called, isTrue);
    });
  });
}
