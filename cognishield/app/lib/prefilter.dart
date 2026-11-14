/// Privacy prefilter: text from the clipboard is only sent to the backend when it
/// contains a link or typical scam wording. Passwords and ordinary chat stay on the device.
final RegExp _urlRe = RegExp(
  r'(https?://|www\.)\S+|\b[a-z0-9-]+\.(com|co\.id|go\.id|id|net|org|xyz|top|click|link|info|site|online|cc|ly|gl|gd|vip|club|shop|store|app)\b',
  caseSensitive: false,
);

final RegExp _wordRe = RegExp(
  r'otp|kode verifikasi|\bpin\b|password|kata sandi|diblokir|dibekukan|diretas|verifikasi|hadiah|undian|menang|'
  r'transfer|rekening|pinjam|pinjol|investasi|profit|deposit|slot|togel|judi|\.apk|install|polisi|kejaksaan|ojk|'
  r'bpjs|pajak|bea cukai|kurir|paket|resi|lowongan|gaji|komisi|nomor baru|bitcoin|kripto|crypto|sebar|bayar|'
  r'tagihan|denda|tilang|klaim|gratis|bonus|anydesk|virus|tebusan|ransom|congratulations|you have won|verify your',
  caseSensitive: false,
);

bool hasLink(String text) => _urlRe.hasMatch(text);

/// True when [text] is worth checking.
bool looksRisky(String text) {
  final t = text.trim();
  if (t.length < 12 || t.length > 2000) return false;
  final hasSpace = t.contains(RegExp(r'\s'));
  if (!hasSpace && !hasLink(t)) return false; // single token: likely a password or code
  return hasLink(t) || _wordRe.hasMatch(t);
}
