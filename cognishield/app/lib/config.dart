import 'package:flutter/foundation.dart';

/// Default backend address per platform. Can be overridden in Settings
/// (needed for a physical phone: use your laptop's LAN IP, e.g. http://192.168.1.10:8000).
String defaultBaseUrl() {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000'; // Android emulator -> host machine
  }
  return 'http://127.0.0.1:8000';
}
