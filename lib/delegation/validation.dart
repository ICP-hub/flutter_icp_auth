import 'dart:convert';
import 'package:agent_dart/agent_dart.dart';
import '../internal/auth_idl.dart';

class DelegationValidation {
  static HttpAgent? validationAgent;
  static Future<List<Object>> validateDelegation(
      String pubKey, String privKey, String delegation) async {
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

      // Creating HttpAgent using the delegation Identity
      validationAgent = HttpAgent(
          options: HttpAgentOptions(
        identity: delegationIdentity,
        host: 'icp-api.io',
      ));

      // Creating a new CanisterActor using the new Agent
      CanisterActor newActor = CanisterActor(
          ActorConfig(
            canisterId: Principal.fromText('cni7b-uaaaa-aaaag-qc6ra-cai'),
            agent: validationAgent,
          ),
          FieldsMethod.idl);

      // Calling whoAmI to confirm API call
      var validatedPrincipal =
          await newActor.getFunc(FieldsMethod.whoAmI)?.call([]);

      return [true, validatedPrincipal, validationAgent!, delegationIdentity];
    } catch (e) {
      return [false, e];
    }
  }
}
