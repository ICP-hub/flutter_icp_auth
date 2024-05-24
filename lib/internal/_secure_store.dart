import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Class to store, read and delete delegation values
class SecureStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Writing the delegation values to the secure storage
  static writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
    log("Written: $key");
  }

  // Reading delegation values from the secure storage
  static readSecureData(String key) async {
    var storedValue = await _storage.read(key: key);
    log("Stored $key : $storedValue");
    return storedValue;
  }

  // Deleting delegation values from the secure storage
  static deleteSecureData(String key) async {
    await _storage.delete(key: key);
    log("Deleted $key");
  }
}
