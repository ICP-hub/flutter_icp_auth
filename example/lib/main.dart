import 'dart:async';
import 'integration.dart';

import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_icp_auth/flutter_icp_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter IID Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter IID Login'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _principalId = "Log in to see your principal";
  bool isLoggedIn = false;

  // ---------------------------------------------------
  // Must declare these in your application
  // ---------------------------------------------------

  bool isLocal =
      false; // To confirm if you running your project locally or using main-net. Change it to true if running locally
  Service idlService =
      FieldsMethod.idl; // Idl service (Location: lib/integration.dart)
  String backendCanisterId =
      'cni7b-uaaaa-aaaag-qc6ra-cai'; // Replace it with your backend canisterId
  String middlePageCanisterId =
      'nplfj-4yaaa-aaaag-qjucq-cai'; // Replace it with your middlePage canisterId

  // ---------------------------------------------------------------
  // Add this in the app to check the login state when app is opened
  // ---------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    AuthLogIn.checkLoginStatus(isLocal, backendCanisterId).then((loggedIn) {
      setState(() {
        isLoggedIn = loggedIn;
        if (loggedIn) {
          _principalId = AuthLogIn.getPrincipal;
        }
      });
      if (!loggedIn) {
        UrlListener.handleInitialUri(_manualLogin, () {});
        UrlListener.initListener(_manualLogin);
      }
    });
  }

  @override
  void dispose() {
    UrlListener.cancelListener();
    super.dispose();
  }

  // Add this function to call the fetchAgent function to get the log-in values
  Future<void> _manualLogin(Uri uri) async {
    List<dynamic> result = await AuthLogIn.fetchAgent(
        uri.queryParameters, isLocal, backendCanisterId, idlService);
    if (result.isNotEmpty) {
      setState(() {
        isLoggedIn = uri.queryParameters['status'] == "true" ? true : false;
        _principalId = result[0];
      });
    } else {
      setState(() {
        isLoggedIn = false;
        _principalId = "Log in to see your principal";
      });
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 200,
                height: 100,
                child: Image.asset('assets/images/logo.png'),
              ),
              const Text(
                'Principal ID:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _principalId,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              isLoggedIn == false
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink,
                        elevation: 8,
                      ),
                      onPressed: () async {
                        // replace the argument host and scheme with your apps host and scheme
                        await AuthLogIn.authenticate(isLocal,
                            middlePageCanisterId, "exampleCallback", "example");
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink,
                        elevation: 8,
                      ),
                      onPressed: () async {
                        List<Object> logoutValidation =
                            await AuthLogout.logout(isLocal, backendCanisterId);
                        // Changing the state of log in and principal id based on this example app requirement
                        setState(() {
                          isLoggedIn = logoutValidation.whereType<bool>().first;
                          _principalId = isLoggedIn
                              ? logoutValidation[1].toString()
                              : "Log in to see your principal";
                        });
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
