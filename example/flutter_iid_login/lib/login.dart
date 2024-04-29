import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_icp_auth/internal/_secure_store.dart';
import 'package:uni_links/uni_links.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_icp_auth/flutter_icp_auth.dart';

import 'services/integration.dart';
import 'helper/loader.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CustomLoader customLoader = CustomLoader();
  String _principalId = "Your principal id will appear here";
  bool isLoggedIn = false;

  // ---------------------------------------------------
  // Must define these in your application
  // ---------------------------------------------------

  bool isLocal =
      false; // To confirm if you running your project locally or using main-net
  StreamSubscription? _sub;
  late List<Object> delegationObject;
  List<String> canisterId = [
    'cni7b-uaaaa-aaaag-qc6ra-cai'
  ]; // Main-net backend canister Id
  // List<String> canisterId = ['be2us-64aaa-aaaaa-qaabq-cai']; // Local backend canister Id
  List<Service> idlService = [FieldsMethod.idl]; // Add the idl services here

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
    if (isLoggedIn == false) {
      _initUniLinks();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Logout() to clear the session data and check the user login state
  void logout() async {
    await SecureStore.deleteSecureData("pubKey");
    await SecureStore.deleteSecureData("privKey");
    await SecureStore.deleteSecureData("delegation");

    setState(() {
      isLoggedIn = false;
      _principalId = "Your principal id will appear here";
    });

    _checkIfLoggedIn();
  }

  // To check whether user session is active
  // It reads data from the secure store and delegates with those data if present
  // Else it will follow the normal method of log in using the Sign In button
  void _checkIfLoggedIn() async {
    customLoader.showLoader('Checking...');

    delegationObject = await IIDLoginState.readData();
    isLoggedIn = delegationObject.whereType<bool>().first;

    customLoader.dismissLoader();

    if (isLoggedIn) {
      customLoader.showSuccess("Login Successful");
      whoAmI();
    } else {
      customLoader.showLoader("New user/Session expired, login again");
      Future.delayed(const Duration(seconds: 2), () {
        customLoader.dismissLoader();
      });
    }
  }

  // Initial state of the application
  // Receives the delegation string from the middle page
  // Sends param to the flutter_icp_auth package to get the Agent and the delegationIdentity
  // Runs whoAmI() to demonstrate actor creation and making API calls
  Future<void> _initUniLinks() async {
    Future<void> processUri(Uri? uri) async {
      if (uri != null) {
        try {
          delegationObject =
              await IIDLoginState.fetchAgent(uri.queryParameters, isLocal);
          log("Delegation Object: $delegationObject");
          customLoader.showSuccess("Login Successful");
          whoAmI();
        } catch (e) {
          log("fetchAgent Error: $e");
        }
      }
    }

    try {
      final initialLink = await getInitialUri();
      await processUri(initialLink);
    } catch (e) {
      log("initialLink Error: $e");
    }

    _sub = uriLinkStream.listen(
      (Uri? uri) async {
        await processUri(uri);
      },
      onError: (err) {
        log("uriLinkStream Error: $err");
      },
    );
  }

  // Extracts the HttpAgent from the delegation object received
  // Creates a new CanisterActor using the new Agent
  // Calling whoAmI() function to confirm user login and get user principalId
  Future<void> whoAmI() async {
    try {
      customLoader.dismissLoader();
      Future.delayed(const Duration(seconds: 1), () {
        customLoader.showLoader("Loading your principal");
      });

      // Calling getActor() from the package to get the list of all the canister actors
      List<CanisterActor> newActors =
          IIDLoginState.getActor(canisterId, idlService);

      var myPrincipal =
          await newActors[0].getFunc(FieldsMethod.whoAmI)?.call([]);
      log("My whoAmI principal: $myPrincipal");

      customLoader.dismissLoader();

      setState(() {
        _principalId = myPrincipal;
        isLoggedIn = true;
      });
    } catch (e) {
      log("whoAmI Error: $e");
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
                  ? const IIDLogin(
                      text: "Sign In With Internet Identity",
                      isComplete: true,
                      scheme: "example",
                      host: "exampleCallback")
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink,
                        elevation: 8,
                        // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      ),
                      onPressed: () {
                        logout();
                      },
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
