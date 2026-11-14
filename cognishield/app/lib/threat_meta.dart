import 'package:flutter/material.dart';

/// English display name, icon and color for every threat category the backend reports.
class ThreatMeta {
  const ThreatMeta(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

const Map<String, ThreatMeta> threatMeta = {
  'phishing': ThreatMeta('Phishing', Icons.link_off_rounded, Color(0xFFEF4444)),
  'credential': ThreatMeta('OTP & Data Theft', Icons.password_rounded, Color(0xFFEF4444)),
  'account_takeover': ThreatMeta('Account Hijack', Icons.manage_accounts_rounded, Color(0xFFEF4444)),
  'malware': ThreatMeta('Malware / APK', Icons.bug_report_rounded, Color(0xFFDC2626)),
  'prize_scam': ThreatMeta('Prize Scam', Icons.card_giftcard_rounded, Color(0xFFF59E0B)),
  'investment': ThreatMeta('Investment Scam', Icons.trending_up_rounded, Color(0xFFF59E0B)),
  'gambling': ThreatMeta('Online Gambling', Icons.casino_rounded, Color(0xFFF97316)),
  'loan': ThreatMeta('Illegal Loan', Icons.request_quote_rounded, Color(0xFFF97316)),
  'job_scam': ThreatMeta('Job Scam', Icons.work_outline_rounded, Color(0xFFF59E0B)),
  'impersonation': ThreatMeta('Fake Authority', Icons.badge_outlined, Color(0xFF8B5CF6)),
  'courier': ThreatMeta('Parcel Scam', Icons.local_shipping_outlined, Color(0xFFF59E0B)),
  'family': ThreatMeta('Fake Family Number', Icons.family_restroom_rounded, Color(0xFF8B5CF6)),
  'extortion': ThreatMeta('Extortion / Ransom', Icons.gpp_maybe_rounded, Color(0xFFDC2626)),
  'tech_support': ThreatMeta('Fake Support', Icons.support_agent_rounded, Color(0xFF8B5CF6)),
  'marketplace': ThreatMeta('Buy/Sell Scam', Icons.storefront_rounded, Color(0xFFF59E0B)),
  'romance': ThreatMeta('Romance Scam', Icons.favorite_border_rounded, Color(0xFFEC4899)),
  'hoax': ThreatMeta('Hoax / Propaganda', Icons.fact_check_outlined, Color(0xFF2F5BEA)),
  'unsafe_link': ThreatMeta('Unsafe Link', Icons.link_off_rounded, Color(0xFFEF4444)),
};

ThreatMeta metaFor(String id, [String? fallbackName]) =>
    threatMeta[id] ?? ThreatMeta(fallbackName ?? id, Icons.shield_outlined, const Color(0xFF2F5BEA));
