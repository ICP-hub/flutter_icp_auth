import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_icp_auth/flutter_icp_auth.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription? _sub;
  final String _linkMessage = "Your principal id will appear here";
  late List<Object> delegationObject;

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

  Future<void> _initUniLinks() async {
    try {
      final initialLink = await getInitialUri();
      if (initialLink != null) {
        delegationObject =
            await IIDLoginState.fetchAgent(initialLink.queryParameters, true);
        log("Delegation Object: $delegationObject");
      }
    } catch (e) {
      log("Error: $e");
    }

    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        delegationObject = await IIDLoginState.fetchAgent(uri.queryParameters, true);
        log("Delegation Object: $delegationObject");
      }
    }, onError: (err) {
      log("Error: $err");
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
                _linkMessage,
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
