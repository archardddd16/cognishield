import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'config.dart';
import 'models.dart';
import 'native.dart';

/// Server data (stats + scan history) shared by all screens.
class ThreatStore extends ChangeNotifier {
  ThreatStore(this._api);
  final ApiClient Function() _api;

  Stats? stats;
  List<HistoryItem> history = const [];
  String? error;
  bool loading = false;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final api = _api();
      stats = await api.stats();
      history = await api.history();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

/// App settings (persisted with shared_preferences).
class AppState extends ChangeNotifier {
  AppState() {
    store = ThreatStore(() => api);
  }

  late final ThreatStore store;

  ThemeMode themeMode = ThemeMode.light;
  bool alerts = true; // vibrate on high-risk results
  bool protection = true; // master switch: Clipboard Guard + Notification Guard
  bool notifGuard = false; // Android: check incoming notifications
  bool? listenerEnabled; // Android notification access: true/false, null = unknown or not installed
  String userName = 'Archard Garcia';
  String baseUrl = defaultBaseUrl();
  ApiClient api = ApiClient(defaultBaseUrl());

  SharedPreferences? _prefs;

  String get firstName {
    final n = userName.trim();
    return n.isEmpty ? 'there' : n.split(RegExp(r'\s+')).first;
  }

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      themeMode = (_prefs!.getBool('dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
      alerts = _prefs!.getBool('alerts') ?? true;
      protection = _prefs!.getBool('protection') ?? true;
      userName = _prefs!.getString('userName') ?? userName;
      baseUrl = _prefs!.getString('baseUrl') ?? defaultBaseUrl();
      api = ApiClient(baseUrl);
      notifGuard = _prefs!.getBool('notifGuard') ?? false;
    } catch (_) {
      // Storage unavailable: keep defaults.
    }
    syncNative();
    refreshNative();
  }

  /// Push backend address + on/off state to the Android notification service.
  void syncNative() {
    NativeBridge.syncConfig(baseUrl: baseUrl, enabled: protection && notifGuard);
  }

  /// Re-check whether the user granted notification access (call when the app resumes).
  Future<void> refreshNative() async {
    if (!NativeBridge.supported) return;
    listenerEnabled = await NativeBridge.isListenerEnabled();
    notifyListeners();
  }

  void setNotifGuard(bool v) {
    notifGuard = v;
    _prefs?.setBool('notifGuard', v);
    notifyListeners();
    syncNative();
    if (v) NativeBridge.requestPostNotifications();
  }

  void setDark(bool v) {
    themeMode = v ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setBool('dark', v);
    notifyListeners();
  }

  void setAlerts(bool v) {
    alerts = v;
    _prefs?.setBool('alerts', v);
    notifyListeners();
  }

  void setProtection(bool v) {
    protection = v;
    _prefs?.setBool('protection', v);
    notifyListeners();
    syncNative();
  }

  void setUserName(String v) {
    userName = v.trim();
    _prefs?.setString('userName', userName);
    notifyListeners();
  }

  void setBaseUrl(String url) {
    baseUrl = url.trim().isEmpty ? defaultBaseUrl() : url.trim();
    api = ApiClient(baseUrl);
    _prefs?.setString('baseUrl', baseUrl);
    notifyListeners();
    syncNative();
    store.refresh();
  }

  void resetBaseUrl() => setBaseUrl(defaultBaseUrl());

  /// Call after every scan: refreshes the dashboard data and vibrates on danger.
  void onScanDone({required bool danger}) {
    store.refresh();
    if (danger && alerts) {
      HapticFeedback.heavyImpact();
    }
  }
}
