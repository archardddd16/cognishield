import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../native.dart';
import '../painters.dart';
import '../theme.dart';
import '../threat_meta.dart';
import '../widgets.dart';
import 'scanner_screen.dart';

class ProtectionScreen extends StatelessWidget {
  const ProtectionScreen({super.key, required this.state});
  final AppState state;

  void _open(BuildContext context, ScanMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ScannerScreen(state: state, initialMode: mode)),
    );
  }

  Future<void> _scanClipboard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    String text = '';
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      text = data?.text?.trim() ?? '';
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Clipboard access was denied.')));
      return;
    }
    if (text.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Your clipboard is empty. Copy a link or message first.')));
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ScannerScreen(
          state: state,
          initialMode: ScanMode.auto,
          initialText: text,
          autoScan: true,
        ),
      ),
    );
  }

  void _tips(BuildContext context) {
    const tips = [
      'Never share OTP, PIN or password with anyone, including "bank staff".',
      'Banks and officials never ask you to install an .apk file.',
      'Short links hide the real destination. Check them before opening.',
      '"Prize", "account blocked" and "last chance" messages are pressure tactics.',
      'Before sharing viral news, search the claim on turnbackhoax.id or cekfakta.com.',
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final p = Palette.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scam Tips', style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final t in tips)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: kSafe),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t, style: TextStyle(color: p.text, height: 1.3))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final on = state.protection;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const ScreenHeader(title: 'Protection'),
              AppCard(
                color: p.tint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const ShieldLogo(size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Real-Time Protection',
                                  style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(on ? 'Active' : 'Paused',
                                  style: TextStyle(color: on ? kSafe : p.muted, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Switch(value: on, onChanged: state.setProtection),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'Clipboard Guard works on the mobile app. On web, use the scanners below.'
                          : 'Master switch. Clipboard Guard checks risky-looking text you copied when you return to the app; Notification Guard checks incoming notifications (Android).',
                      style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              _NotificationGuardCard(state: state),
              const SectionTitle('Security Features'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _Feature(
                    icon: Icons.auto_awesome_rounded,
                    color: kPrimary,
                    title: 'Scan Anything',
                    desc: 'Auto-detects every threat',
                    onTap: () => _open(context, ScanMode.auto),
                  ),
                  _Feature(
                    icon: Icons.language_rounded,
                    color: kPrimary,
                    title: 'Link Shield',
                    desc: 'Checks links for phishing',
                    onTap: () => _open(context, ScanMode.link),
                  ),
                  _Feature(
                    icon: Icons.fact_check_outlined,
                    color: kWarning,
                    title: 'Hoax Check',
                    desc: 'Analyzes news & claims',
                    onTap: () => _open(context, ScanMode.news),
                  ),
                  _Feature(
                    icon: Icons.sms_outlined,
                    color: kSafe,
                    title: 'Message Guard',
                    desc: 'Spots scam messages',
                    onTap: () => _open(context, ScanMode.message),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                onTap: () => _scanClipboard(context),
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.content_paste_search_rounded, color: kPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Clipboard', style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('Check copied text now', style: TextStyle(color: p.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: kPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => _tips(context),
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.tips_and_updates_outlined, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scam Tips', style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('Stay one step ahead', style: TextStyle(color: p.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
              const SectionTitle('What We Detect'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in threatMeta.entries)
                    if (e.key != 'unsafe_link') ThreatPill(meta: e.value),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.color, required this.title, required this.desc, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AppCard(
      onTap: onTap,
      color: p.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconBadge(icon: icon, color: color, size: 42),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(color: p.muted, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Android Notification Guard: reads incoming notifications (via the native service)
/// and alerts when one looks like a scam, phishing or malware attempt.
class _NotificationGuardCard extends StatelessWidget {
  const _NotificationGuardCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final supported = NativeBridge.supported;
    final access = state.listenerEnabled; // true / false / null (unknown or not installed)
    final active = supported && access == true && state.notifGuard && state.protection;

    String status;
    Color statusColor = p.muted;
    if (!supported) {
      status = 'Available on the Android app only.';
    } else if (access == null) {
      status = 'Setup needed: run setup_android.ps1 once, then rebuild the app.';
      statusColor = kWarning;
    } else if (access == false) {
      status = 'Notification access is off. Grant it so CogniShield can read incoming notifications.';
      statusColor = kWarning;
    } else if (active) {
      status = 'Active: incoming notifications are checked and risky ones trigger an alert.';
      statusColor = kSafe;
    } else {
      status = 'Ready. Switch on to start checking notifications.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(icon: Icons.notifications_active_outlined, color: kPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notification Guard',
                          style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(active ? 'Active' : 'Off',
                          style: TextStyle(color: active ? kSafe : p.muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Switch(
                  value: state.notifGuard,
                  onChanged: (!supported || access == null)
                      ? null
                      : (v) {
                          state.setNotifGuard(v);
                          if (v && access == false) NativeBridge.openListenerSettings();
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(status, style: TextStyle(color: statusColor, fontSize: 12.5, height: 1.35)),
            if (supported && access == false)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton.tonal(
                  onPressed: NativeBridge.openListenerSettings,
                  child: const Text('Grant notification access'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
