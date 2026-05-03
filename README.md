# simple_jwt_manager

(en)Japanese ver is [here](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README_JA.md).  
(ja)この解説の日本語版は[ここ](https://github.com/MasahideMori-SimpleAppli/simple_jwt_manager/blob/main/README_JA.md)にあります。

## Overview
This is a package to support authentication using JWT.  
It supports the "Resource Owner Password Credentials Grant" defined in
[RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3),
as well as general user registration.  
Sign-out processing follows [RFC 7009](https://datatracker.ietf.org/doc/html/rfc7009).

## Package structure

From v2.0.0, network functionality has been separated into `simple_https_service`.

| Package | Responsibility |
|---|---|
| `simple_jwt_manager` | ROPC authentication and JWT token management |
| [`simple_https_service`](https://pub.dev/packages/simple_https_service) | HTTPS communication, retry, and timing control |

Add both to your `pubspec.yaml`:

```yaml
dependencies:
  simple_jwt_manager: ^2.0.0
  simple_https_service: ^1.0.0
```

For error reporting, add [`simple_error_reporter`](https://pub.dev/packages/simple_error_reporter) separately.

## Features
- User registration, sign-in, sign-out, and account deletion
- Automatic access token refresh using a refresh token
- Token persistence support via `toDict()` / `savedData`
- `updateJwtCallback` for saving tokens to local storage whenever they change
- `ROPCAuthStream` for stream-based sign-in state management (e.g., with GoRouter)
- `ROPCConfig` singleton for independent retry control

Two implementations are provided:
- `ROPCClient`: Works on both web and native platforms.
- `ROPCClientForNative`: Native-only, with support for self-signed certificates via `badCertificateCallback`.

## Usage

### Basic setup

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
      // Called whenever the token changes or is deleted.
      // Save or clear savedData in local storage here.
    },
  );

  runApp(const MyApp());
}
```

### Sign-in and sign-out

```dart
// Sign in
final res = await ropcClient.signIn(email, password);
switch (res.resultStatus) {
  case EnumServerResponseStatus.success:
    // Signed in successfully.
  case EnumServerResponseStatus.signInRequired:
    // Incorrect credentials.
  default:
    // Handle timeout / server error / other error.
}

// Sign out
await ropcClient.signOut();
```

### Authenticated request

Retrieve the current access token and pass it to `HttpsService`:

```dart
import 'package:simple_https_service/simple_https_service.dart';

final jwt = await ropcClient.getToken();
if (jwt != null) {
  final res = await HttpsService.post(
    url, body, EnumPostEncodeType.json, jwt: jwt,
  );
}
```

### Token persistence

```dart
// Serialize the current token state for storage:
final Map<String, dynamic> savedData = ropcClient.toDict();

// Restore on next launch:
final ropcClient = ROPCClient(
  ...,
  savedData: savedData,
);
```

### Stream-based state (e.g. GoRouter)

```dart
final authStream = ROPCAuthStream();

authStream.getStream().listen((EnumAuthStatus status) {
  // Navigate based on status.
});

// Update the stream after sign-in or sign-out:
ropcClient.updateStream(authStream);
```

### Retry configuration

By default, all HTTP calls are sent once with no retries.  
Use `ROPCConfig` to enable retries independently of any global retry settings in `simple_https_service`.

```dart
// Call this before creating ROPCClient, e.g. in main().
ROPCConfig().maxRetries = 3;
ROPCConfig().baseDelay = const Duration(seconds: 1);
ROPCConfig().maxJitter = const Duration(milliseconds: 500);
ROPCConfig().retryCondition = (url, res, error) {
  return res.resultStatus == EnumServerResponseStatus.serverError ||
      error != null;
};
```

`retryCondition` must be set for retries to occur. If it is `null`, `maxRetries` is ignored and no retries are attempted — regardless of any global `RetryConfig` settings.

## Support
Basically no support.  
If you have any problem please open an issue on Github.  
This package is low priority, but may be fixed.

## About version control
The C part will be changed at the time of version upgrade.  
However, versions less than 1.0.0 may change the file structure regardless of the following rules.  
- Changes such as adding variables, structure change that cause problems when reading previous files.
    - C.X.X
- Adding methods, etc.
    - X.C.X
- Minor changes and bug fixes.
    - X.X.C

## License
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

- "Dart" and "Flutter" are trademarks of Google LLC.  
  *This package is not developed or endorsed by Google LLC.*
