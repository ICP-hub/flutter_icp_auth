import '../internal/_secure_store.dart';
import '../authentication/login.dart';

class AuthLogout {
  static Future<List<Object>> logout() async {
    await SecureStore.deleteSecureData("pubKey");
    await SecureStore.deleteSecureData("privKey");
    await SecureStore.deleteSecureData("delegation");

    return AuthLogIn.getDelegations();
  }
}
