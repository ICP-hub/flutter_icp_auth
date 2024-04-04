import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class IIDLogin extends StatefulWidget {
  const IIDLogin({
    super.key,
    required this.isComplete,
    required this.text,
    required this.scheme,
    required this.host,
    this.onPrincipalIdReceived,
    this.onError,
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
  final String scheme;
  final String host;
  final Function(String)? onPrincipalIdReceived;
  final Function(String)? onError;

  @override
  IIDLoginState createState() => IIDLoginState();
}

class IIDLoginState extends State<IIDLogin> {
  CanisterActor? newActor;
  static Ed25519KeyIdentity? newIdentity;
  String? publicKeyString;
  static String? principalId;
  String? _error;

  static get getPrincipal => principalId;

  static List<Object> fetchAgent(Map<String, String> queryParams) {
    String delegationString = queryParams['del'].toString();
    String decodedDelegation = Uri.decodeComponent(delegationString);
    DelegationChain delegationChain =
        DelegationChain.fromJSON(jsonDecode(decodedDelegation));
    DelegationIdentity delegationIdentity =
        DelegationIdentity(newIdentity!, delegationChain);

    principalId = delegationIdentity.getPrincipal().toText();

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
    return [newAgent, delegationIdentity];
  }

// ---------------- Authentication ----------------
  Future<void> authenticate() async {
    try {
      newIdentity = await Ed25519KeyIdentity.generate(null);
      Ed25519PublicKey publicKey = newIdentity!.getPublicKey();
      var publicKeyDer = publicKey.toDer();
      publicKeyString = bytesToHex(publicKeyDer);
      // ---- Local replica ----
      const baseUrl = 'http://localhost:4943';
      final url =
          '$baseUrl?sessionkey=$publicKeyString&canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai&host=${widget.host}&scheme=${widget.scheme}';
      // ---- Main-net replica ----
      // const baseUrl = 'https://ckjzv-zyaaa-aaaag-qc6rq-cai.icp0.io';
      // final url = '$baseUrl?sessionkey=$publicKeyString&host=${widget.host}&scheme=${widget.scheme}';
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
        ),
        child: Text(
          widget.text,
          style: widget.textStyle,
        ),
      ),
    );
  }
}
