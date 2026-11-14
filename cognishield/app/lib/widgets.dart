import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'threat_meta.dart';

/// Rounded-square icon with a tinted background.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 44});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.soft(0.14), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// Round icon button used in headers.
class CircleAction extends StatelessWidget {
  const CircleAction({super.key, required this.icon, required this.onPressed, this.dot = false, this.tooltip});
  final IconData icon;
  final VoidCallback? onPressed;
  final bool dot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: p.card,
        shape: BoxShape.circle,
        border: Border.all(color: p.line),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon, color: p.text, size: 22)),
          if (dot)
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: kDanger, shape: BoxShape.circle, border: Border.all(color: p.card, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.actions = const []});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.text)),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// One row of the threat feed.
class ThreatTile extends StatelessWidget {
  const ThreatTile({super.key, required this.item, this.onTap});
  final HistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = levelColor(item.level);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            child: Icon(levelIcon(item.level), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: p.text)),
                const SizedBox(height: 2),
                Text(item.preview.replaceAll('\n', ' '),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: p.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(timeAgo(item.time), style: TextStyle(fontSize: 12, color: p.muted)),
          Icon(Icons.chevron_right_rounded, color: p.muted, size: 20),
        ],
      ),
    );
  }
}

/// Risk bar + reasons + advice. Shared by result card and history sheet.
class RiskDetails extends StatelessWidget {
  const RiskDetails({
    super.key,
    required this.level,
    required this.riskScore,
    required this.reasons,
    required this.advice,
    this.urlInfo,
    this.links = const [],
  });

  final String level;
  final int riskScore;
  final List<String> reasons;
  final String advice;
  final UrlInfo? urlInfo;
  final List<LinkVerdict> links;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = levelColor(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Risk score', style: TextStyle(color: p.muted, fontSize: 13)),
            const Spacer(),
            Text('$riskScore / 100', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: riskScore.clamp(0, 100) / 100,
            minHeight: 9,
            color: c,
            backgroundColor: c.soft(0.15),
          ),
        ),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Why', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 4),
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Container(width: 5, height: 5, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(r, style: TextStyle(color: p.text, height: 1.3))),
                ],
              ),
            ),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Links found', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          for (final l in links.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(levelIcon(l.level), size: 16, color: levelColor(l.level)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text('${l.riskScore}', style: TextStyle(color: levelColor(l.level), fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
        if (urlInfo != null && urlInfo!.hasUrl) ...[
          const SizedBox(height: 14),
          Text('Link: ${urlInfo!.url}', style: TextStyle(fontWeight: FontWeight.w600, color: p.text)),
          Text('${urlInfo!.status} (risk ${urlInfo!.riskScore})', style: TextStyle(color: p.muted)),
        ],
        if (advice.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: kPrimary),
                const SizedBox(width: 8),
                Expanded(child: Text(advice, style: TextStyle(color: p.text, height: 1.3))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Small colored pill with the icon and name of a threat type.
class ThreatPill extends StatelessWidget {
  const ThreatPill({super.key, required this.meta});
  final ThreatMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: meta.color.soft(0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 14, color: meta.color),
          const SizedBox(width: 5),
          Text(meta.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: meta.color)),
        ],
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.categories, this.max = 4});
  final List<ThreatCategory> categories;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final c in categories.take(max)) ThreatPill(meta: metaFor(c.id, c.name))],
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result, this.heading});
  final ScanResult result;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = levelColor(result.level);
    final headline = heading ?? result.title;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.soft(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.soft(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                child: Icon(levelIcon(result.level), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c)),
                    if (result.label.isNotEmpty && result.label != headline)
                      Text(result.label, style: TextStyle(color: p.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          CategoryChips(categories: result.categories),
          const SizedBox(height: 16),
          RiskDetails(
            level: result.level,
            riskScore: result.riskScore,
            reasons: result.reasons,
            advice: result.advice,
            links: result.links,
          ),
        ],
      ),
    );
  }
}

Future<void> showResultSheet(BuildContext context, ScanResult r, {String? heading}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ResultCard(result: r, heading: heading),
      ),
    ),
  );
}

Future<void> showHistorySheet(BuildContext context, HistoryItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final p = Palette.of(ctx);
      final c = levelColor(item.level);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    child: Icon(levelIcon(item.level), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.headline, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
                        Text('${item.label} · ${timeAgo(item.time)}', style: TextStyle(color: p.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(14)),
                child: Text('"${item.preview}"', style: TextStyle(color: p.text, fontStyle: FontStyle.italic)),
              ),
              CategoryChips(categories: item.categories),
              const SizedBox(height: 16),
              RiskDetails(level: item.level, riskScore: item.riskScore, reasons: item.reasons, advice: item.advice),
            ],
          ),
        ),
      );
    },
  );
}
