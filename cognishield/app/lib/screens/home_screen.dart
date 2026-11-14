import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';
import 'risk_graph_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, required this.onOpenTab});

  final AppState state;
  final ValueChanged<int> onOpenTab;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  ({String title, String sub, Color color, IconData icon}) _status(ThreatStore s) {
    final st = s.stats;
    if (st == null) {
      return s.error != null
          ? (title: 'Backend Offline', sub: "Can't reach the server", color: kWarning, icon: Icons.cloud_off_rounded)
          : (title: 'Checking...', sub: 'Contacting the server', color: kPrimary, icon: Icons.sync_rounded);
    }
    switch (st.status) {
      case 'DANGER':
        return (title: 'Threat Detected', sub: 'Review your latest alerts', color: kDanger, icon: Icons.priority_high_rounded);
      case 'ATTENTION':
        return (title: 'Stay Alert', sub: 'Recent suspicious activity', color: kWarning, icon: Icons.priority_high_rounded);
      default:
        return (title: "You're Protected!", sub: 'All systems secure', color: kSafe, icon: Icons.check_rounded);
    }
  }

  void _scoreInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Security Score'),
        content: const Text(
          'Starts at 100 and drops with the average risk of your latest 20 scans '
          '(score = 100 - 0.6 x average risk). Scan more links and messages to make it meaningful.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([state, state.store]),
        builder: (context, _) {
          final store = state.store;
          final stats = store.stats;
          final status = _status(store);
          final trend = scoreTrend(store.history);
          final score = stats?.securityScore ?? 100;
          final delta = trend.length >= 2 ? trend.last - trend.first : null;
          final latest = store.history.take(3).toList();

          return RefreshIndicator(
            onRefresh: store.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                // Greeting
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: TextStyle(color: p.muted, fontSize: 14)),
                          Text('${state.firstName}! \u{1F44B}',
                              style: TextStyle(color: p.text, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    CircleAction(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Threat feed',
                      dot: (stats?.threatsBlocked ?? 0) > 0,
                      onPressed: () => onOpenTab(1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Protected card
                AppCard(
                  color: p.tint,
                  child: Row(
                    children: [
                      const ShieldLogo(size: 54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(status.title, style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(status.sub, style: TextStyle(color: p.muted)),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: status.color.soft(0.18), shape: BoxShape.circle),
                        child: Icon(status.icon, color: status.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Security score
                AppCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => RiskGraphScreen(state: state)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Security Score', style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _scoreInfo(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Icon(Icons.info_outline_rounded, size: 17, color: p.muted),
                          ),
                          const Spacer(),
                          Text('Risk graph', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const Icon(Icons.chevron_right_rounded, color: kPrimary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('$score', style: TextStyle(color: p.text, fontSize: 50, fontWeight: FontWeight.w800, height: 1.0)),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                                    child: Text('/100', style: TextStyle(color: p.muted, fontSize: 16)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (delta != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(delta >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                        color: delta >= 0 ? kSafe : kDanger),
                                    Text(
                                      '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                                      style: TextStyle(color: delta >= 0 ? kSafe : kDanger, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                )
                              else
                                Text('No trend yet', style: TextStyle(color: p.muted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Sparkline(values: trend, color: score >= 60 ? kSafe : kDanger, height: 72)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Live threat feed
                SectionTitle(
                  'Live Threat Feed',
                  trailing: InkWell(
                    onTap: () => onOpenTab(1),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Text('View all', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, color: kPrimary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                if (store.error != null && stats == null)
                  AppCard(
                    color: kWarning.soft(0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.error!, style: TextStyle(color: p.text)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: store.refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                else if (latest.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        Icon(Icons.radar_rounded, size: 34, color: p.muted),
                        const SizedBox(height: 8),
                        Text('No scans yet', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Check a link or message in the Protection tab.',
                            textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                        const SizedBox(height: 10),
                        FilledButton(onPressed: () => onOpenTab(2), child: const Text('Open Protection')),
                      ],
                    ),
                  )
                else
                  for (final h in latest) ThreatTile(item: h, onTap: () => showHistorySheet(context, h)),
              ],
            ),
          );
        },
      ),
    );
  }
}
