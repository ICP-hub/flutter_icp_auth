import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class IIDLogin extends StatefulWidget {
  const IIDLogin({
    super.key,
    required this.isComplete,
    required this.text,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.gradient = const LinearGradient(
      colors: [Color(0xFF522785), Color(0xFFED1E79)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    this.textStyle =
        const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
  });

  final bool isComplete;
  final String text;
  final BorderRadius borderRadius;
  final Gradient gradient;
  final TextStyle textStyle;

  @override
  IIDLoginState createState() => IIDLoginState();
}

class IIDLoginState extends State<IIDLogin> {
  CanisterActor? newActor;
  StreamSubscription? _sub;
  Ed25519KeyIdentity? newIdentity;
  String? publicKeyString;
  String? principalId;
  String? _error;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> initUniLinks() async {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null && uri.scheme == 'auth' && uri.host == 'callback') {
        var queryParams = uri.queryParameters;

        String delegationString = queryParams['del'].toString();

        String decodedDelegation = Uri.decodeComponent(delegationString);

        DelegationChain delegationChain =
            DelegationChain.fromJSON(jsonDecode(decodedDelegation));

        DelegationIdentity delegationIdentity =
            DelegationIdentity(newIdentity!, delegationChain);

        principalId = delegationIdentity.getPrincipal().toHex();

        HttpAgent newAgent = HttpAgent(
          options: HttpAgentOptions(
            identity: delegationIdentity,
            // ---- Uncomment the following line to use main-net replica ----
            host: 'icp-api.io',
          ),
          // ---- Uncomment the following 3 lines to use a local replica ----
          // defaultHost: 'localhost',
          // defaultPort: 4943,
          // defaultProtocol: 'http',
        );

        log('Agent: $newAgent');

        // Creating Canister Actor -----------------------
        // newActor = CanisterActor(
        //     ActorConfig(
        //       // ---- Main-net replica ----
        //       canisterId: Principal.fromText('c7oiy-yqaaa-aaaag-qc6sa-cai'),
        //       // ---- Local replica ----
        //       // canisterId: Principal.fromText('bw4dl-smaaa-aaaaa-qaacq-cai'),
        //       agent: newAgent,
        //     ),
        //     FieldsMethod.idl);
      }
    });
  }

// ---------------- Authentication ----------------
  Future<void> authenticate() async {
    try {
      newIdentity = await Ed25519KeyIdentity.generate(null);
      Ed25519PublicKey publicKey = newIdentity!.getPublicKey();
      var publicKeyDer = publicKey.toDer();
      publicKeyString = bytesToHex(publicKeyDer);
      // ---- Local replica ----
      // const baseUrl = 'http://localhost:4943';
      // final url =
      //     '$baseUrl?sessionkey=$publicKeyString&canisterId=asrmz-lmaaa-aaaaa-qaaeq-cai';
      // ---- Main-net replica ----
      const baseUrl = 'https://ckjzv-zyaaa-aaaag-qc6rq-cai.icp0.io';
      final url = '$baseUrl?sessionkey=$publicKeyString';
      await launch(
        url,
        customTabsOption: const CustomTabsOption(
          toolbarColor: Colors.blue,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
        ),
        safariVCOption: const SafariViewControllerOption(
          preferredBarTintColor: Colors.black,
          preferredControlTintColor: Colors.white,
          barCollapsingEnabled: true,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to open URL: $e';
      });
      log('Error: $_error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: widget.borderRadius,
      ),
      child: ElevatedButton(
        onPressed: authenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius,
          ),
          padding: const EdgeInsets.all(16),
        ), // Change here: Use the function reference
        child: Text(
          widget.text,
          style: widget.textStyle,
        ),
      ),
    );
  }
}
