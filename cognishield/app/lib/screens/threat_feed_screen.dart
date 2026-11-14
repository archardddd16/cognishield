import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'scanner_screen.dart';

class ThreatFeedScreen extends StatefulWidget {
  const ThreatFeedScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ThreatFeedScreen> createState() => _ThreatFeedScreenState();
}

class _ThreatFeedScreenState extends State<ThreatFeedScreen> {
  // All / Blocked (danger) / Detected (warning) / Resolved (safe)
  static const _filters = ['All', 'Blocked', 'Detected', 'Resolved'];
  int _filter = 0;

  bool _matches(String level) => switch (_filter) {
        1 => level == 'danger',
        2 => level == 'warning',
        3 => level == 'safe',
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: widget.state.store,
        builder: (context, _) {
          final store = widget.state.store;
          final items = store.history.where((h) => _matches(h.level)).toList();
          return Column(
            children: [
              ScreenHeader(
                title: 'Threat Feed',
                actions: [
                  CircleAction(
                    icon: Icons.add_rounded,
                    tooltip: 'Scan something',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ScannerScreen(state: widget.state)),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ChoiceChip(
                    label: Text(_filters[i]),
                    selected: _filter == i,
                    showCheckmark: false,
                    selectedColor: kPrimary,
                    backgroundColor: p.tint,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _filter == i ? Colors.white : kPrimary,
                    ),
                    onSelected: (_) => setState(() => _filter = i),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: store.refresh,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          children: [
                            Icon(store.error != null ? Icons.cloud_off_rounded : Icons.inbox_rounded,
                                size: 44, color: p.muted),
                            const SizedBox(height: 10),
                            Text(
                              store.error ??
                                  (store.history.isEmpty ? 'No scans yet.\nTap + to check a link or message.' : 'Nothing in this filter.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.muted, height: 1.4),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          itemCount: items.length,
                          itemBuilder: (_, i) => ThreatTile(
                            item: items[i],
                            onTap: () => showHistorySheet(context, items[i]),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
