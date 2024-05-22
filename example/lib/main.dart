import 'dart:async';
import 'dart:developer';

import 'integration.dart';

import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_icp_auth/flutter_icp_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _principalId = "Log In to see your principal";
  bool isLoggedIn = false;

  // ---------------------------------------------------
  // Must declare these in your application
  // ---------------------------------------------------

  bool _initialized = false;
  bool isLocal =
      false; // To confirm if you running your project locally or using main-net. Change it to true if running locally
  StreamSubscription? _sub;
  String backendCanisterId =
      'cni7b-uaaaa-aaaag-qc6ra-cai'; // Replace it with your backend canisterId
  String middlePageCanisterId =
      'nplfj-4yaaa-aaaag-qjucq-cai'; // Replace it with your middlePage canisterId
  Service idlService =
      FieldsMethod.idl; // Idl service (Location: lib/services/integration.dart)

  // ---------------------------------------------------------------
  // Add this in the app to check the login state when app is opened
  // ---------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    try {
      // Checking initial link
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      log("Initial Link Error: $e");
    }

    // Attaching listener for later links
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (err) {
      log("Later Link Error: $err");
    });
  }

  void _handleUri(uri) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_initialized) {
      // Handling URI when coming from middle page
      String status = uri.queryParameters['status'].toString();
      List<Object> delegationObject = await AuthLogIn.fetchAgent(
          uri.queryParameters, isLocal, backendCanisterId, idlService);

      setState(() {
        isLoggedIn = status == "true" ? true : false;
        _principalId = delegationObject[0].toString();
      });
    } else {
      // Handling URI when app is reloaded or opened directly
      String? savedUri = prefs.getString('last_uri');
      if (savedUri == uri) {
        log('Ignoring last saved URI');
      } else {
        // Performing action based on the URI
        List<Object> validatedDelegation = await AuthLogIn.getDelegations();

        setState(() {
          isLoggedIn = validatedDelegation.whereType<bool>().first == true
              ? true
              : false;
        });
        if (isLoggedIn == true) {
          setState(() {
            _principalId = validatedDelegation[1].toString();
          });
        }
        prefs.setString('last_uri', uri.toString());
      }
      _initialized = true;
    }
  }

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
                      onPressed: () {
                        AuthLogIn.authenticate(isLocal, middlePageCanisterId,
                            "exampleCallback", "example");
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
                            await AuthLogout.logout();
                        setState(() {
                          isLoggedIn =
                              logoutValidation.whereType<bool>().first == true
                                  ? true
                                  : false;
                          _principalId = isLoggedIn == true
                              ? logoutValidation[1].toString()
                              : "Log In to see your principal";
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
