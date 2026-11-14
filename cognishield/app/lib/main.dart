import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'painters.dart';
import 'prefilter.dart';
import 'screens/home_screen.dart';
import 'screens/protection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/threat_feed_screen.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(CogniShieldApp(state: state));
}

class CogniShieldApp extends StatelessWidget {
  const CogniShieldApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'CogniShield',
        debugShowCheckedModeBanner: false,
        themeMode: state.themeMode,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: SplashScreen(state: state),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.state});
  final AppState state;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.store.refresh();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => HomeShell(state: widget.state),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: GradientBox(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShieldLogo(size: 150, face: true),
                const SizedBox(height: 28),
                Text('CogniShield', style: TextStyle(color: p.text, fontSize: 38, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Your Safe, Worry-Free Life', style: TextStyle(color: p.muted, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shell with bottom navigation + Clipboard Guard
// ---------------------------------------------------------------------------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});
  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  String? _lastClip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      widget.state.refreshNative(); // user may have just granted notification access
      _checkClipboard();
    }
  }

  /// Clipboard Guard: when the app comes back to the foreground and the clipboard
  /// holds a link or scam-like wording, check it and warn if it looks risky.
  Future<void> _checkClipboard() async {
    if (kIsWeb || !widget.state.protection) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty || text == _lastClip || text.length > 2000) return;
      _lastClip = text;
      if (!looksRisky(text)) return; // privacy: ordinary text never leaves the device
      final r = await widget.state.api.analyzeAuto(text, source: 'clipboard');
      widget.state.onScanDone(danger: r.level == 'danger');
      if (!mounted || r.level == 'safe') return;
      await showResultSheet(context, r, heading: 'Risky text in your clipboard');
    } catch (_) {
      // Clipboard guard is best-effort: ignore errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: GradientBox(
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(state: s, onOpenTab: (i) => setState(() => _index = i)),
            ThreatFeedScreen(state: s),
            ProtectionScreen(state: s),
            SettingsScreen(state: s),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Threats'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Protection'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
