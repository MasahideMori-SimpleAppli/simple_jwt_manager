import 'package:flutter/material.dart';
import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';

// TODO select client version.
late final ROPCClient ropcClient; // web or native
// late final ROPCClientForNative
//     ropcClient; // native, use self-signed certificates

// You can use this if you want to redirect with GoRouter.
final ROPCAuthStream authStream = ROPCAuthStream();

// TODO: Please make sure to rewrite this URL.
const String registerURL = "https://your-endpoint.example.com/register";
const String signInURL = "https://your-endpoint.example.com/sign-in";
const String refreshURL = "https://your-endpoint.example.com/refresh";
const String signOutURL = "https://your-endpoint.example.com/sign-out";
const String deleteUserURL = "https://your-endpoint.example.com/delete-user";
// URL for posting data with JWT in auth header.
const String postingDataURL = "https://your-endpoint.example.com/data";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: configure retry behavior for JWT operations independently of
  // simple_https_service globals. By default, no retries are attempted.
  // ROPCConfig().maxRetries = 3;
  // ROPCConfig().retryCondition = (url, res, error) {
  //   return res.resultStatus == EnumServerResponseStatus.serverError ||
  //       error != null;
  // };

  Map<String, dynamic>? savedData;
  // TODO: If necessary, restore the token in your own way.
  // savedData = jsonDecode(The token from storage etc.);
  // In practical use, it may be useful to wrap ROPCClient in a singleton class.
  // Because ROPCClient class is not a singleton,
  // you can manage multiple tokens separately in multiple ROPCClient.
  // You can easily create savedData by calling ropcClient.toDict().

  // For web or native device.
  ropcClient = ROPCClient(
      registerURL: registerURL,
      signInURL: signInURL,
      refreshURL: refreshURL,
      signOutURL: signOutURL,
      deleteUserURL: deleteUserURL,
      savedData: savedData,
      updateJwtCallback: (Map<String, dynamic> savedData) {
        // TODO
        // You can save the JWT on your device.
        // This is also called if the token is deleted.
      });

  // For native device only.
  // This version can support self-signed certificates.
  // ropcClient = ROPCClientForNative(
  //     registerURL: registerURL,
  //     signInURL: signInURL,
  //     refreshURL: refreshURL,
  //     signOutURL: signOutURL,
  //     deleteUserURL: deleteUserURL,
  //     badCertificateCallback: (X509Certificate cert, String host, int port) {
  //       // TODO
  //       // The condition is checked here, and if it returns true,
  //       // self-signed certificates are allowed.
  //       return true;
  //     },
  //     savedData: savedData,
  //     updateJwtCallback: (Map<String, dynamic> savedData) {
  //       // TODO
  //       // You can save the JWT on your device.
  //       // This is also called if the token is deleted.
  //     });

  // TODO stream value test. In practice, it is used in conjunction with GoRouter.
  authStream.getStream().listen((EnumAuthStatus status) {
    debugPrint("AuthStatusStream:${status.name}");
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _tecID = TextEditingController();
  final TextEditingController _tecPW = TextEditingController();

  @override
  void dispose() {
    _tecID.dispose();
    _tecPW.dispose();
    super.dispose();
  }

  // TODO: Please note that this is just a usage example and will not typically be laid out like this.
  @override
  Widget build(BuildContext context) {
    // TODO You can get the signIn status like this:
    // final bool isSignedIn = ropcClient.isSignedIn();
    return MaterialApp(
      title: 'Simple JWT Manager Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple JWT Manager Example'),
          backgroundColor: const Color.fromARGB(255, 0, 255, 0),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: 320,
                    margin: EdgeInsets.zero,
                    child: TextField(
                      controller: _tecID,
                      decoration:
                          const InputDecoration(hintText: "User ID (e-mail)"),
                    )),
                Container(
                    width: 320,
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: TextField(
                      controller: _tecPW,
                      decoration:
                          const InputDecoration(hintText: "User password"),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 48, 0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        ropcClient
                            .register(_tecID.text, _tecPW.text)
                            .then((ServerResponse v) {
                          debugPrint(v.toString());
                          switch (v.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // TODO: Handle user registration complete.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle timeout.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server error.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              throw Exception();
                            case EnumServerResponseStatus.cancelled:
                              // TODO: Handle cancellation.
                              break;
                          }
                        });
                      },
                      child: const Text('Register'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        ropcClient
                            .signIn(_tecID.text, _tecPW.text)
                            .then((ServerResponse v) {
                          debugPrint(v.toString());
                          switch (v.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // If you are working with streams, do the following:
                              ropcClient.updateStream(authStream);
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle timeout.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server error.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // TODO: The username or password is incorrect.
                              break;
                            case EnumServerResponseStatus.cancelled:
                              // TODO: Handle cancellation.
                              break;
                          }
                        });
                      },
                      child: const Text('SignIn'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        ropcClient.signOut().then((ServerResponse v) {
                          debugPrint(v.toString());
                          switch (v.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // If you are working with streams, do the following:
                              ropcClient.updateStream(authStream);
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle timeout.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server error.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              throw Exception();
                            case EnumServerResponseStatus.cancelled:
                              // TODO: Handle cancellation.
                              break;
                          }
                        });
                      },
                      child: const Text('SignOut'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        ropcClient
                            .deleteUser(_tecID.text, _tecPW.text)
                            .then((ServerResponse v) {
                          debugPrint(v.toString());
                          switch (v.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // If you are working with streams, do the following:
                              ropcClient.updateStream(authStream);
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle timeout.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server error.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // TODO: The username or password is incorrect.
                              break;
                            case EnumServerResponseStatus.cancelled:
                              // TODO: Handle cancellation.
                              break;
                          }
                        });
                      },
                      child: const Text('DeleteUser'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        ropcClient
                            .refreshAndGetNewToken()
                            .then((ServerResponse v) {
                          debugPrint(v.toString());
                          switch (v.resultStatus) {
                            case EnumServerResponseStatus.success:
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle timeout.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server error.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // TODO: goto signIn page.
                              // If you are working with streams, do the following:
                              ropcClient.updateStream(authStream);
                              break;
                            case EnumServerResponseStatus.cancelled:
                              // TODO: Handle cancellation.
                              break;
                          }
                        });
                      },
                      child: const Text('Refresh token(debug only)'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () async {
                        String? jwt = await ropcClient.getToken();
                        debugPrint("token: ${jwt ?? "null"}");
                        if (jwt != null) {
                          // TODO Add your implementation to do some operation in the backend.

                          // For web or native device.
                          final ServerResponse res = await HttpsService.post(
                              postingDataURL,
                              {"test": "test params"},
                              EnumPostEncodeType.json,
                              jwt: jwt);

                          // For native device only.
                          // This version can support self-signed certificates.
                          // final ServerResponse res =
                          //     await HttpsServiceForNative.post(
                          //         postingDataURL,
                          //         {"test": "test params"},
                          //         EnumPostEncodeType.json,
                          //         jwt: jwt, badCertificateCallback:
                          //             (X509Certificate cert, String host,
                          //                 int port) {
                          //   // TODO
                          //   // The condition is checked here, and if it returns true,
                          //   // self-signed certificates are allowed.
                          //   return true;
                          // });

                          debugPrint("Server response: $res");
                          switch (res.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // TODO: Handle success.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle timeout.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server error.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // TODO: The token has expired, goto signIn page.
                              // If you are working with streams, do the following:
                              ropcClient.updateStream(authStream);
                              break;
                            case EnumServerResponseStatus.cancelled:
                              // TODO: Handle cancellation.
                              break;
                          }
                        } else {
                          debugPrint("The token is null.");
                          // TODO: The token has expired, goto signIn page.
                          // If you are working with streams, do the following:
                          ropcClient.updateStream(authStream);
                        }
                      },
                      child: const Text('Post data to EndPoints'),
                    )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
