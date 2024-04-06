import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static readSecureData(String key) async {
    var storedValue = await _storage.read(key: key);
    log("Stored Delegation : $storedValue");
  }

  static deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }
}