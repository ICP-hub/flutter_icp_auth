import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_icp_auth/flutter_icp_auth.dart';

import 'services/integration.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription? _sub;
  late List<Object> delegationObject;
  String _principalId = "Your principal id will appear here";
  bool isLocal = true; // To confirm if you running your project locally or using main-net
  String canisterId = 'asrmz-lmaaa-aaaaa-qaaeq-cai'; // Backend canister Id

  @override
  void initState() {
    super.initState();
    _initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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

          setState(() {
            _principalId = "Loading..";
          });

          IIDLoginState.readData(isLocal, canisterId);
          whoAmI();
        } catch (e) {
          log("Error: $e");
        }
      }
    }

    try {
      final initialLink = await getInitialUri();
      await processUri(initialLink);
    } catch (e) {
      log("Error: $e");
    }

    _sub = uriLinkStream.listen(
      (Uri? uri) async {
        await processUri(uri);
      },
      onError: (err) {
        log("Error: $err");
      },
    );
  }

  // Extracts the HttpAgent from the delegation object received
  // Creates a new CanisterActor using the new Agent
  // Calling whoAmI() function to confirm user login and get user principalId
  Future<void> whoAmI() async {
    HttpAgent? extractedAgent =
        delegationObject.whereType<HttpAgent>().firstOrNull;

    CanisterActor newActor = CanisterActor(
        ActorConfig(
          canisterId: Principal.fromText(canisterId),
          agent: extractedAgent!,
        ),
        FieldsMethod.idl);

    var myPrincipal = await newActor.getFunc(FieldsMethod.whoAmI)?.call([]);
    log("My principal: $myPrincipal");

    setState(() {
      _principalId = myPrincipal;
    });
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
              const IIDLogin(
                text: "Sign In With Internet Identity",
                isComplete: true,
                scheme: "example",
                host: "exampleCallback",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
