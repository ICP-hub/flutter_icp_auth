import 'dart:developer';
import 'dart:convert';
import 'package:agent_dart/agent_dart.dart';

abstract class NewFieldsMethod {
  static const whoAmI = 'whoami';
  static final ServiceClass idl = IDL.Service(
    {
      NewFieldsMethod.whoAmI: IDL.Func([], [IDL.Text], []),
    },
  );
}

class DelegationValidation {
  static Future<List<dynamic>> validateDelegation(
      String pubKey, String privKey, String delegation, bool local, String canisterId) async {
    try {
      // Generating appIdentity using the public and private key
      var keyPairValues = [pubKey, privKey];
      Ed25519KeyIdentity newIde =
          Ed25519KeyIdentity.fromParsedJson(keyPairValues);

      // Creating delegationIdentity using the delegationString and the appIdentity.
      String decodedDelegation = Uri.decodeComponent(delegation);
      DelegationChain delegationChain =
          DelegationChain.fromJSON(jsonDecode(decodedDelegation));
      DelegationIdentity delegationIdentity =
          DelegationIdentity(newIde, delegationChain);

      // Creating HTTPAgent using the new delegationIdentity
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

      // Creating a new CanisterActor using the new Agent
      CanisterActor newActor = CanisterActor(
          ActorConfig(
            canisterId: Principal.fromText(canisterId),
            agent: newAgent,
          ),
          NewFieldsMethod.idl);

      // Calling whoAmI to confirm API call
      var myPrincipal =
          await newActor.getFunc(NewFieldsMethod.whoAmI)?.call([]);
      log("My new principal: $myPrincipal");

      return ["Validation Successful", delegationIdentity, newAgent, newActor];

    } catch (e) {
      log("Invalid Delegation Error: $e");
      throw 'Invalid delegation data';
    }
  }
}
