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
    try {
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
    } catch (e) {
      log("Fetch Agent Error: $e");
      return [];
    }
  }

  // --------------------------------------------------
  // Get principal ID
  // --------------------------------------------------
  static get getPrincipal => _principalId;

  // --------------------------------------------------
  // Read stored data and validate delegation
  // --------------------------------------------------
  static Future<List<Object>> getDelegations(
      bool isLocal, String canisterId) async {
    String? pubKey = await SecureStore.readSecureData("pubKey");
    String? privKey = await SecureStore.readSecureData("privKey");
    String? delegation = await SecureStore.readSecureData("delegation");

    if (pubKey == null || privKey == null || delegation == null) {
      return [false];
    } else {
      var validatedDelegationValues =
          await DelegationValidation.validateDelegation(
              isLocal, canisterId, pubKey, privKey, delegation);
      log("Validated Values, $validatedDelegationValues");

      return validatedDelegationValues;
    }
  }

  // --------------------------------------------------
  // Check Delegations
  // --------------------------------------------------
  static Future<bool> checkLoginStatus(
      bool isLocal, String backendCanisterId) async {
    List<Object> validatedDelegation =
        await getDelegations(isLocal, backendCanisterId);
    if (validatedDelegation.whereType<bool>().first) {
      _principalId = validatedDelegation[1].toString();
      return true;
    } else {
      return false;
    }
  }

  static Future<List<Object?>> manualLogin(Uri uri, bool isLocal,
      String backendCanisterId, Service idlService) async {
    List<dynamic> result = await AuthLogIn.fetchAgent(
        uri.queryParameters, isLocal, backendCanisterId, idlService);
    if (result.isNotEmpty) {
      bool isLoggedIn = uri.queryParameters['status'] == "true" ? true : false;
      _principalId = result[0].toString();
      return [isLoggedIn, _principalId];
    } else {
      return [false, "Log in to see your principal"];
    }
  }

  // --------------------------------------------------
  // Get Actor functions
  // --------------------------------------------------

  // Get a single actor
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
