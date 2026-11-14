import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

class RiskGraphScreen extends StatelessWidget {
  const RiskGraphScreen({super.key, required this.state});
  final AppState state;

  (String, Color) _riskLevel(int score) {
    if (score >= 80) return ('Low Risk', kSafe);
    if (score >= 50) return ('Medium Risk', kWarning);
    return ('High Risk', kDanger);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GradientBox(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Risk Graph')),
        body: ListenableBuilder(
          listenable: state.store,
          builder: (context, _) {
            final store = state.store;
            final score = store.stats?.securityScore ?? 100;
            final (label, color) = _riskLevel(score);
            final items = store.history.take(60).toList();
            final suspicious = store.history.where((h) => h.level == 'warning').length;
            final blocked = store.history.where((h) => h.level == 'danger').length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                AppCard(
                  color: p.tint,
                  child: Row(
                    children: [
                      const ShieldLogo(size: 44),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Risk Analysis', style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Sparkline(values: scoreTrend(store.history), color: color, height: 48)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      RiskGraph(
                        items: items,
                        onTap: (item) => showHistorySheet(context, item),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend(color: kGraphSafe, text: 'Safe', muted: p.muted),
                          const SizedBox(width: 18),
                          _Legend(color: kWarning, text: 'Suspicious', muted: p.muted),
                          const SizedBox(width: 18),
                          _Legend(color: kDanger, text: 'Malicious', muted: p.muted),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items.isEmpty ? 'No scans yet. Each scan you run appears here as a node.' : 'Each dot is one scan. Tap a dot for details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded, color: kPrimary),
                          const SizedBox(width: 8),
                          Text('Detailed Analysis', style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatRow(label: 'Total Scans', value: '${store.stats?.totalScans ?? store.history.length}'),
                      _StatRow(label: 'Suspicious Activity', value: '$suspicious'),
                      _StatRow(label: 'Blocked Threats', value: '$blocked'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text, required this.muted});
  final Color color;
  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: p.muted))),
          Text(value, style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
