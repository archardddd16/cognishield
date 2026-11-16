import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: state.userName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) state.setUserName(c.text);
  }

  Future<void> _clearHistory(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear scan history?'),
        content: const Text('This removes all scans from the server and resets your dashboard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.api.clearHistory();
      await state.store.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('History cleared.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About CogniShield'),
        content: const SingleChildScrollView(
          child: Text(
            'CogniShield v1.0.0\n\n'
            'AI-powered security & threat intelligence for hoaxes, phishing links and scam messages.\n\n'
            'This prototype analyzes text with rules and heuristics on your own backend server. '
            'Links are judged by domain patterns and are never opened. If the server owner set a VirusTotal key, only the link address (not your message) is also checked on VirusTotal. '
            'Text you scan (and links copied while Clipboard Guard is on) is sent to that server only.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _help(BuildContext context) {
    final p = Palette.of(context);
    const steps = [
      'Protection tab: pick Link Shield, Hoax Check or Message Guard and paste what you want checked.',
      'Threat Feed: every scan is logged. Tap a row for the reasons behind the result.',
      'Home: your security score and trend. Tap the score card for the risk graph.',
      'Cannot connect? Start the backend, then set its address in Settings > Backend Server.',
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & Support', style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 11, backgroundColor: kPrimary, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(steps[i], style: TextStyle(color: p.text, height: 1.3))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _backend(BuildContext context) {
    return showDialog<void>(context: context, builder: (_) => _BackendDialog(state: state));
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const ScreenHeader(title: 'Settings'),
              AppCard(
                onTap: () => _editName(context),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF5B86FF), Color(0xFF2F5BEA)]),
                      ),
                      child: Text(
                        state.firstName.characters.first.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.userName.isEmpty ? 'Guest' : state.userName,
                              style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 17)),
                          Text('Tap to edit name', style: TextStyle(color: p.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
              const SectionTitle('App Preferences'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    _Tile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Threat Alerts',
                      subtitle: 'Vibrate on high-risk results',
                      trailing: Switch(value: state.alerts, onChanged: state.setAlerts),
                    ),
                    _Tile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: Switch(value: state.themeMode == ThemeMode.dark, onChanged: state.setDark),
                    ),
                    _Tile(
                      icon: Icons.dns_outlined,
                      title: 'Backend Server',
                      subtitle: state.baseUrl,
                      trailing: Icon(Icons.chevron_right_rounded, color: p.muted),
                      onTap: () => _backend(context),
                    ),
                  ],
                ),
              ),
              const SectionTitle('About'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    _Tile(
                      icon: Icons.info_outline_rounded,
                      title: 'About CogniShield',
                      trailing: Icon(Icons.chevron_right_rounded, color: p.muted),
                      onTap: () => _about(context),
                    ),
                    _Tile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      trailing: Icon(Icons.chevron_right_rounded, color: p.muted),
                      onTap: () => _help(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: () => _clearHistory(context),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear Scan History'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: p.tint,
                  foregroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: p.text),
      title: Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 12.5)),
      trailing: trailing,
    );
  }
}

class _BackendDialog extends StatefulWidget {
  const _BackendDialog({required this.state});
  final AppState state;

  @override
  State<_BackendDialog> createState() => _BackendDialogState();
}

class _BackendDialogState extends State<_BackendDialog> {
  late final TextEditingController _url = TextEditingController(text: widget.state.baseUrl);
  bool _testing = false;
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    widget.state.setBaseUrl(_url.text);
    _url.text = widget.state.baseUrl;
    setState(() {
      _testing = true;
      _message = null;
    });
    try {
      final ok = await widget.state.api.health();
      if (!mounted) return;
      setState(() {
        _ok = ok;
        _message = ok ? 'Connected to the backend.' : 'The backend answered, but its status is not ok.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _message = e.toString();
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AlertDialog(
      title: const Text('Backend Server'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chrome: http://127.0.0.1:8000\nAndroid emulator: http://10.0.2.2:8000\nReal phone: http://YOUR-LAPTOP-IP:8000 (same Wi-Fi)',
              style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            ),
            if (_testing)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator())
            else if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_message!, style: TextStyle(color: _ok ? kSafe : kDanger)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.state.resetBaseUrl();
            _url.text = widget.state.baseUrl;
          },
          child: const Text('Default'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(onPressed: _testing ? null : _saveAndTest, child: const Text('Save & Test')),
      ],
    );
  }
}
