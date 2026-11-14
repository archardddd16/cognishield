import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the Android-only Notification Guard (see android_native/).
/// Every call is safe on other platforms or when the native module is not installed.
class NativeBridge {
  static const MethodChannel _ch = MethodChannel('cognishield/native');

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Tell the native service where the backend is and whether to check notifications.
  static Future<void> syncConfig({required String baseUrl, required bool enabled}) async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<bool>('syncConfig', {'baseUrl': baseUrl, 'enabled': enabled});
    } catch (_) {}
  }

  /// true/false = notification access granted or not; null = native module not installed.
  static Future<bool?> isListenerEnabled() async {
    if (!supported) return null;
    try {
      return await _ch.invokeMethod<bool>('isListenerEnabled');
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> openListenerSettings() async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<bool>('openListenerSettings');
    } catch (_) {}
  }

  static Future<void> requestPostNotifications() async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<bool>('requestPostNotifications');
    } catch (_) {}
  }
}
