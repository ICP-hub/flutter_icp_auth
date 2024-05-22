import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:agent_dart/agent_dart.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

import '../internal/_secure_store.dart';
import '../delegation/validation.dart';
import '../internal/auth_idl.dart';

class AuthLogIn {
  static Ed25519KeyIdentity? _newIdentity;
  static String? publicKeyString;
  static String? _principalId;
  static HttpAgent? newAgent;

  // --------------------------------------------------
  // Authentication
  // --------------------------------------------------
  static Future<void> authenticate(bool isLocal, String middlePageCanisterId,
      String appHost, String appScheme) async {
    try {
      _newIdentity = await Ed25519KeyIdentity.generate(null);
      Ed25519PublicKey publicKey = _newIdentity!.getPublicKey();
      var publicKeyDer = publicKey.toDer();
      publicKeyString = bytesToHex(publicKeyDer);

      final url = isLocal
          ? 'http://localhost:4943?sessionkey=$publicKeyString&host=$appHost&scheme=$appScheme&canisterId=$middlePageCanisterId'
          : 'https://$middlePageCanisterId.icp0.io?sessionkey=$publicKeyString&host=$appHost&scheme=$appScheme';

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
      log('Error: $e');
    }
  }

  // --------------------------------------------------
  // Create Agent function
  // --------------------------------------------------
  static Future<List<Object>> fetchAgent(Map<String, String> queryParams,
      bool local, String canisterId, Service idLService) async {
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
        "privKey", bytesToHex(_newIdentity!.getKeyPair().secretKey));
    SecureStore.writeSecureData("delegation", delegationString);

    _principalId = delegationIdentity.getPrincipal().toText();

    newAgent = local
        ? HttpAgent(
            options: HttpAgentOptions(
              identity: delegationIdentity,
            ),
            defaultHost: 'localhost',
            defaultPort: 4943,
            defaultProtocol: 'http',
          )
        : HttpAgent(
            options: HttpAgentOptions(
              identity: delegationIdentity,
              host: 'icp-api.io',
            ),
          );

    CanisterActor delegatedActor = getActor(canisterId, idLService);

    var hexPrincipalId =
        await delegatedActor.getFunc(FieldsMethod.whoAmI)?.call([]);

    return [hexPrincipalId, newAgent!, delegationIdentity];
  }

  // --------------------------------------------------
  // Get principal ID
  // --------------------------------------------------
  static get getPrincipal => _principalId;

  // --------------------------------------------------
  // Read stored data and validate delegation
  // --------------------------------------------------
  static Future<List<Object>> getDelegations() async {
    if ((await SecureStore.readSecureData("pubKey") == null) ||
        (await SecureStore.readSecureData("privKey") == null) ||
        (await SecureStore.readSecureData("delegation") == null)) {
      return [false];
    } else {
      String pubKey = await SecureStore.readSecureData("pubKey");
      String privKey = await SecureStore.readSecureData("privKey");
      String delegation = await SecureStore.readSecureData("delegation");

      var validatedDelegationValues =
          await DelegationValidation.validateDelegation(
              pubKey, privKey, delegation);
      log("Validated Values, $validatedDelegationValues");

      return validatedDelegationValues;
    }
  }

  // --------------------------------------------------
  // Get Actor functions
  // --------------------------------------------------

  static CanisterActor getActor(String canisterIds, Service idlServices) {
    HttpAgent actorAgent =
        newAgent == null ? DelegationValidation.validationAgent! : newAgent!;

    CanisterActor newActor = CanisterActor(
        ActorConfig(
          canisterId: Principal.fromText(canisterIds),
          agent: actorAgent,
        ),
        idlServices);

    return newActor;
  }

  // Get all actors
  static List<CanisterActor> getAllActors(
      List<String> canisterIds, List<Service> idlServices) {
    List<CanisterActor> actorsList = [];

    for (int i = 0; i < canisterIds.length; i++) {
      String canisterId = canisterIds[i];
      Service idlService = idlServices[i];

      HttpAgent actorAgent =
          newAgent == null ? DelegationValidation.validationAgent! : newAgent!;

      CanisterActor newActor = CanisterActor(
          ActorConfig(
            canisterId: Principal.fromText(canisterId),
            agent: actorAgent,
          ),
          idlService);

      actorsList.add(newActor);
    }

    return actorsList;
  }
}
