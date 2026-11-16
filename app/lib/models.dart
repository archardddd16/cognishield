import 'threat_meta.dart';

class ThreatCategory {
  const ThreatCategory({required this.id, required this.name, required this.score});
  final String id;
  final String name;
  final int score;

  factory ThreatCategory.fromJson(Map<String, dynamic> j) => ThreatCategory(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
      );

  static List<ThreatCategory> listFrom(Object? raw) =>
      ((raw as List?) ?? const []).whereType<Map<String, dynamic>>().map(ThreatCategory.fromJson).toList();
}

class LinkVerdict {
  const LinkVerdict({required this.url, required this.status, required this.level, required this.riskScore});
  final String url;
  final String status;
  final String level;
  final int riskScore;

  factory LinkVerdict.fromJson(Map<String, dynamic> j) => LinkVerdict(
        url: (j['url'] as String?) ?? '',
        status: (j['status'] as String?) ?? '',
        level: (j['level'] as String?) ?? 'safe',
        riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
      );
}

class UrlInfo {
  const UrlInfo({
    required this.hasUrl,
    this.url,
    this.status,
    this.riskScore = 0,
    this.reasons = const [],
  });

  final bool hasUrl;
  final String? url;
  final String? status;
  final int riskScore;
  final List<String> reasons;

  factory UrlInfo.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const UrlInfo(hasUrl: false);
    return UrlInfo(
      hasUrl: j['has_url'] == true,
      url: j['detected_url'] as String?,
      status: j['url_status'] as String?,
      riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
      reasons: ((j['reasons'] as List?) ?? const []).map((e) => '$e').toList(),
    );
  }
}

class Tactic {
  const Tactic({required this.name, required this.principle, required this.evidence});
  final String name;
  final String principle;
  final String evidence;

  factory Tactic.fromJson(Map<String, dynamic> j) => Tactic(
        name: (j['name'] as String?) ?? '',
        principle: (j['principle'] as String?) ?? '',
        evidence: (j['evidence'] as String?) ?? '',
      );
}

class ShieldLayer {
  const ShieldLayer({
    required this.id,
    required this.name,
    required this.active,
    required this.fired,
    required this.detail,
  });
  final String id;
  final String name;
  final bool active;
  final bool fired;
  final String detail;

  factory ShieldLayer.fromJson(Map<String, dynamic> j) => ShieldLayer(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        active: j['active'] == true,
        fired: j['fired'] == true,
        detail: (j['detail'] as String?) ?? '',
      );
}

class ScanResult {
  const ScanResult({
    required this.kind,
    required this.label,
    required this.title,
    required this.level,
    required this.riskScore,
    required this.reasons,
    required this.advice,
    required this.urlInfo,
    this.primary,
    this.categories = const [],
    this.links = const [],
    this.confidence = 'tidak_ada_sinyal',
    this.agreedLayers = 0,
    this.totalLayers = 0,
    this.tactics = const [],
    this.layers = const [],
  });

  final String confidence; // tinggi | sedang | rendah | sinyal_lemah | tidak_ada_sinyal
  final int agreedLayers;
  final int totalLayers;
  final List<Tactic> tactics;
  final List<ShieldLayer> layers;

  final String kind;
  final String label;
  final String title;
  final String level; // safe | warning | danger
  final int riskScore;
  final List<String> reasons;
  final String advice;
  final UrlInfo urlInfo;
  final String? primary;
  final List<ThreatCategory> categories;
  final List<LinkVerdict> links;

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    return ScanResult(
      kind: (j['kind'] as String?) ?? '',
      label: (j['label'] as String?) ?? 'Unknown',
      title: (j['warning_title'] as String?) ?? (j['label'] as String?) ?? '',
      level: (j['level'] as String?) ?? 'safe',
      riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
      reasons: ((j['reasons'] as List?) ?? const []).map((e) => '$e').toList(),
      advice: (j['advice'] as String?) ?? '',
      urlInfo: UrlInfo.fromJson(j['url_info'] as Map<String, dynamic>?),
      primary: j['primary'] as String?,
      categories: ThreatCategory.listFrom(j['categories']),
      links: ((j['links'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LinkVerdict.fromJson)
          .toList(),
      confidence: (j['confidence'] as String?) ?? 'tidak_ada_sinyal',
      agreedLayers: ((j['agreement'] as Map?)?['fired'] as num?)?.toInt() ?? 0,
      totalLayers: ((j['agreement'] as Map?)?['total'] as num?)?.toInt() ?? 0,
      tactics: ((j['tactics'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Tactic.fromJson)
          .toList(),
      layers: ((j['layers'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ShieldLayer.fromJson)
          .toList(),
    );
  }
}

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.kind,
    required this.preview,
    required this.label,
    required this.level,
    required this.riskScore,
    required this.time,
    required this.reasons,
    required this.advice,
    this.primary,
    this.source = 'manual',
    this.categories = const [],
  });

  final int id;
  final String kind; // propaganda | url | notification
  final String preview;
  final String label;
  final String level; // safe | warning | danger
  final int riskScore;
  final DateTime? time;
  final List<String> reasons;
  final String advice;
  final String? primary;
  final String source; // manual | clipboard | notification
  final List<ThreatCategory> categories;

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        kind: (j['kind'] as String?) ?? '',
        preview: (j['preview'] as String?) ?? '',
        label: (j['label'] as String?) ?? '',
        level: (j['level'] as String?) ?? 'safe',
        riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
        time: DateTime.tryParse((j['time'] as String?) ?? '')?.toLocal(),
        reasons: ((j['reasons'] as List?) ?? const []).map((e) => '$e').toList(),
        advice: (j['advice'] as String?) ?? '',
        primary: j['primary'] as String?,
        source: (j['source'] as String?) ?? 'manual',
        categories: ThreatCategory.listFrom(j['categories']),
      );

  /// Short English headline, like the Threat Feed rows.
  String get headline {
    if (level == 'safe' || primary == null) return _kindHeadline;
    final name = metaFor(primary!).name;
    return level == 'danger' ? '$name Blocked' : 'Possible $name';
  }

  String get _kindHeadline {
    const names = {
      'url': ['Link Scan Complete', 'Suspicious Link Detected', 'Phishing Link Blocked'],
      'propaganda': ['News Scan Complete', 'Claim Needs Checking', 'Hoax / Propaganda Blocked'],
      'notification': ['Message Scan Complete', 'Suspicious Message', 'Scam Message Blocked'],
    };
    final list = names[kind] ?? const ['Scan Complete', 'Suspicious Activity', 'Threat Blocked'];
    return switch (level) {
      'danger' => list[2],
      'warning' => list[1],
      _ => list[0],
    };
  }
}

class Stats {
  const Stats({
    required this.securityScore,
    required this.status,
    required this.linksScanned,
    required this.hoaxFlagged,
    required this.notificationsScanned,
    required this.threatsBlocked,
    required this.totalScans,
  });

  final int securityScore;
  final String status; // SECURE | ATTENTION | DANGER
  final int linksScanned;
  final int hoaxFlagged;
  final int notificationsScanned;
  final int threatsBlocked;
  final int totalScans;

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        securityScore: (j['security_score'] as num?)?.toInt() ?? 100,
        status: (j['status'] as String?) ?? 'SECURE',
        linksScanned: (j['links_scanned'] as num?)?.toInt() ?? 0,
        hoaxFlagged: (j['hoax_flagged'] as num?)?.toInt() ?? 0,
        notificationsScanned: (j['notifications_scanned'] as num?)?.toInt() ?? 0,
        threatsBlocked: (j['threats_blocked'] as num?)?.toInt() ?? 0,
        totalScans: (j['total_scans'] as num?)?.toInt() ?? 0,
      );
}

/// Running security score over the latest scans (oldest -> newest).
/// Same formula as the backend: 100 - 0.6 * average risk.
List<double> scoreTrend(List<HistoryItem> newestFirst) {
  final recent = newestFirst.take(20).toList().reversed.toList();
  final out = <double>[];
  var sum = 0;
  for (var i = 0; i < recent.length; i++) {
    sum += recent[i].riskScore;
    out.add(100 - 0.6 * sum / (i + 1));
  }
  return out;
}
