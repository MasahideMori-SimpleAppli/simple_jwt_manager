import 'package:flutter/material.dart';
import 'package:simple_jwt_manager/simple_jwt_manager.dart';
import 'dart:convert';

// TODO select client version.
late final ROPCClient ropcClient; // web or native
// late final ROPCClientForNative
//     ropcClient; // native, use self-signed certificates

// TODO: Please make sure to rewrite this URL.
const String registerURL = "https://your end point url";
const String signInURL = "https://your end point url";
const String refreshURL = "https://your end point url";
const String signOutURL = "https://your end point url";
const String deleteUserURL = "https://your end point url";
// URL for posting data with JWT in auth header.
const String postingDataURL = "https://your end point url";

void main() async {
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
      savedData: savedData);

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
  //     savedData: savedData);

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
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                              // TODO: If your backend returns a token, you can store it here.
                              // final String savedData = jsonEncode(ropcClient.toDict());
                              // TODO If you want, save it here in your own way.
                              // TODO Please add a process for when user registration is complete.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: What happens when a timeout occurs.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server side error case.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error case.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // That doesn't usually happen here.
                              throw Exception();
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
                              // TODO: If your backend returns a token, you can store it here.
                              // final String savedData = jsonEncode(ropcClient.toDict());
                              // TODO If you want, save it here in your own way.
                              // TODO Please add a process for when user registration is complete.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: What happens when a timeout occurs.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server side error case.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error case.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // That doesn't usually happen here.
                              throw Exception();
                          }
                        });
                      },
                      child: const Text('SignIn'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () {
                        ropcClient.signOutAllTokens().then((ServerResponse v) {
                          debugPrint(v.toString());
                          switch (v.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // signOut completed.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: What happens when a timeout occurs.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server side error case.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error case.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // That doesn't usually happen here.
                              throw Exception();
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
                              // delete user completed.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: What happens when a timeout occurs.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server side error case.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error case.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // That doesn't usually happen here.
                              throw Exception();
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
                              // completed.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: What happens when a timeout occurs.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle server side error case.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle other error case.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // TODO:
                              debugPrint("SignIn required");
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
                          final ServerResponse res = await UtilHttps.post(
                              postingDataURL,
                              {"test": "test params"},
                              EnumPostEncodeType.json,
                              jwt: jwt);

                          // For native device only.
                          // This version can support self-signed certificates.
                          // final ServerResponse res =
                          //     await UtilHttpsForNative.post(
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

                          // Server response
                          debugPrint("Server response: $res");
                          switch (res.resultStatus) {
                            case EnumServerResponseStatus.success:
                              // TODO: Handle this case.
                              break;
                            case EnumServerResponseStatus.timeout:
                              // TODO: Handle this case.
                              break;
                            case EnumServerResponseStatus.serverError:
                              // TODO: Handle this case.
                              break;
                            case EnumServerResponseStatus.otherError:
                              // TODO: Handle this case.
                              break;
                            case EnumServerResponseStatus.signInRequired:
                              // TODO: Handle this case.
                              break;
                          }
                        } else {
                          // TODO The token has expired or was not obtained, so please go to the sign-in screen.
                          debugPrint("The token is null.");
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
