import 'dart:async';
import 'dart:developer';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';

class UrlListener {
  static StreamSubscription? _sub;

  static void initListener(Function(Uri) onLinkReceived) {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        log('Received URI: $uri');
        onLinkReceived(uri);
      }
    }, onError: (err) {
      log('URI Error: $err');
    });
  }

  static Future<void> handleInitialUri(
      Function(Uri) onLinkReceived, Function onNoUri) async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        log('Initial URI: $initialUri');
        onLinkReceived(initialUri);
      } else {
        onNoUri();
      }
    } on PlatformException {
      log('Failed to receive initial uri.');
      onNoUri();
    } on FormatException catch (e) {
      log('Malformed initial uri: $e');
      onNoUri();
    }
  }

  static void cancelListener() {
    _sub?.cancel();
  }
}
