import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

import '../internal/_secure_store.dart';

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
  static Ed25519KeyIdentity? _newIdentity;
  String? publicKeyString;
  static String? _principalId;
  String? _error;

  // --------------------------------------------------
  // Get principal ID
  // --------------------------------------------------
  static get getPrincipal => _principalId;

  // --------------------------------------------------
  // Create Agent function
  // --------------------------------------------------
  static Future<List<Object>> fetchAgent(
      Map<String, String> queryParams, bool local) async {
    String delegationString = queryParams['del'].toString();
    String decodedDelegation = Uri.decodeComponent(delegationString);
    DelegationChain delegationChain =
        DelegationChain.fromJSON(jsonDecode(decodedDelegation));
    DelegationIdentity delegationIdentity =
        DelegationIdentity(_newIdentity!, delegationChain);

    // Storing keys in local for autoLogin
    SecureStore.writeSecureData(
        "pubKey", bytesToHex(_newIdentity!.getKeyPair().publicKey.toDer()));
    SecureStore.writeSecureData(
        "identity", bytesToHex(_newIdentity!.getKeyPair().secretKey));
    SecureStore.writeSecureData("delegation", delegationString);

    _principalId = delegationIdentity.getPrincipal().toText();

    HttpAgent newAgent;
    if (local) {
      newAgent = HttpAgent(
        options: HttpAgentOptions(
          identity: delegationIdentity,
        ),
        defaultHost: 'localhost',
        defaultPort: 4943,
        defaultProtocol: 'http',
      );
    } else {
      newAgent = HttpAgent(
        options: HttpAgentOptions(
          identity: delegationIdentity,
          host: 'icp-api.io',
        ),
      );
    }

    return [newAgent, delegationIdentity];
  }

  // --------------------------------------------------
  // Authentication
  // --------------------------------------------------
  Future<void> authenticate() async {
    try {
      _newIdentity = await Ed25519KeyIdentity.generate(null);
      Ed25519PublicKey publicKey = _newIdentity!.getPublicKey();
      var publicKeyDer = publicKey.toDer();
      publicKeyString = bytesToHex(publicKeyDer);
      // ---- Local replica ----
      const baseUrl = 'http://localhost:4943';
      final url =
          '$baseUrl?sessionkey=$publicKeyString&canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai&host=${widget.host}&scheme=${widget.scheme}';
      // ---- Main-net replica ----
      // const baseUrl = 'https://ckjzv-zyaaa-aaaag-qc6rq-cai.icp0.io';
      // final url = '$baseUrl?sessionkey=$publicKeyString&host=${widget.host}&scheme=${widget.scheme}';
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: Colors.blue,
            navigationBarColor: Colors.black,
          ),
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          preferredBarTintColor: Colors.blue,
          preferredControlTintColor: Colors.black,
          barCollapsingEnabled: true,
          entersReaderIfAvailable: false,
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
