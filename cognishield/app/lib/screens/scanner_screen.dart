import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

enum ScanMode { auto, link, message, news }

extension on ScanMode {
  String get label => switch (this) {
        ScanMode.auto => 'Auto',
        ScanMode.news => 'News',
        ScanMode.link => 'Link',
        ScanMode.message => 'Message',
      };

  IconData get icon => switch (this) {
        ScanMode.auto => Icons.auto_awesome_rounded,
        ScanMode.news => Icons.fact_check_outlined,
        ScanMode.link => Icons.language_rounded,
        ScanMode.message => Icons.sms_outlined,
      };

  String get blurb => switch (this) {
        ScanMode.auto =>
          'Paste anything: a message, notification, link or news. CogniShield checks it for phishing, scams, malware, account hijacking, gambling, extortion and more.',
        ScanMode.news => 'Paste a news text or viral chain message to check for hoax and propaganda patterns.',
        ScanMode.link => 'Paste a link (bit.ly and other shorteners too). It is judged by domain patterns, and checked on VirusTotal if the server has a key. The link is never opened.',
        ScanMode.message => 'Paste an SMS, chat or notification to spot scams and social engineering.',
      };

  String get hint => switch (this) {
        ScanMode.auto => 'Paste a message, link or news here...',
        ScanMode.news => 'Paste the news text here...',
        ScanMode.link => 'https://bit.ly/hadiah-gratis',
        ScanMode.message => 'Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun',
      };

  List<String> get samples => switch (this) {
        ScanMode.auto => const [
            'Halo mah ini nomor baru aku, hp lama rusak. Tolong transfer dulu 2 juta ke rekening ini, urgent ya jangan bilang papa',
            'Surat tilang elektronik Anda: unduh file TILANG_2026.apk lalu install',
            'Bocoran slot gacor hari ini maxwin! Bonus new member 100% https://slot88-gacor.xyz',
            'Besok rapat kelompok jam 10 di perpustakaan ya',
          ],
        ScanMode.news => const [
            'HEBOH!!! Terungkap rahasia besar yang disembunyikan media! Tolong share ke 10 grup, 100% pasti terjadi!',
            'Menurut BMKG, hujan lebat diperkirakan terjadi di Tangerang pada Sabtu sore.',
          ],
        ScanMode.link => const [
            'https://bit.ly/hadiah-gratis',
            'http://klikbca-verifikasi.xyz/login',
            'https://www.bca.co.id/id/',
          ],
        ScanMode.message => const [
            'Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun',
            'Pihak BCA meminta kode OTP Anda sekarang juga untuk membatalkan transaksi.',
            'Besok rapat kelompok jam 10 di perpustakaan ya.',
          ],
      };
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.state,
    this.initialMode = ScanMode.auto,
    this.initialText,
    this.autoScan = false,
  });

  final AppState state;
  final ScanMode initialMode;
  final String? initialText;
  final bool autoScan;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late ScanMode _mode = widget.initialMode;
  late final TextEditingController _controller = TextEditingController(text: widget.initialText ?? '');
  bool _loading = false;
  ScanResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.autoScan && _controller.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final api = widget.state.api;
      final r = switch (_mode) {
        ScanMode.auto => await api.analyzeAuto(text),
        ScanMode.news => await api.analyzePropaganda(text),
        ScanMode.link => await api.analyzeUrl(text),
        ScanMode.message => await api.analyzeNotification(text),
      };
      if (!mounted) return;
      setState(() => _result = r);
      widget.state.onScanDone(danger: r.level == 'danger');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return GradientBox(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Scan')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            SegmentedButton<ScanMode>(
              showSelectedIcon: false,
              segments: [
                for (final m in ScanMode.values) ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {_mode},
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: kPrimary,
                selectedForegroundColor: Colors.white,
                foregroundColor: p.text,
                backgroundColor: p.card,
              ),
              onSelectionChanged: (s) => setState(() {
                _mode = s.first;
                _result = null;
                _error = null;
              }),
            ),
            const SizedBox(height: 14),
            Text(_mode.blurb, style: TextStyle(color: p.muted, height: 1.35)),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: _mode == ScanMode.link ? 2 : 5,
              maxLength: 5000,
              style: TextStyle(color: p.text),
              decoration: InputDecoration(
                hintText: _mode.hint,
                hintStyle: TextStyle(color: p.muted.soft(0.7)),
                filled: true,
                fillColor: p.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: p.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: p.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: kPrimary, width: 1.6)),
                suffixIcon: IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _controller.clear();
                    _result = null;
                    _error = null;
                  }),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (var i = 0; i < _mode.samples.length; i++)
                  ActionChip(
                    label: Text('Example ${i + 1}'),
                    backgroundColor: p.tint,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
                    onPressed: () => setState(() {
                      _controller.text = _mode.samples[i];
                      _result = null;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loading ? null : _scan,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shield_outlined),
              label: Text(_loading ? 'Analyzing...' : 'Check now'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(16)),
                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
            if (_result != null) ResultCard(result: _result!),
          ],
        ),
      ),
    );
  }
}
