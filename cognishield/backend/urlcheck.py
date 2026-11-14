"""URL / link risk analysis (pure pattern checks; links are never opened)."""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Optional
from urllib.parse import parse_qs, urlparse

DANGER_AT = 60
WARNING_AT = 30


def level_for(score: int) -> str:
    if score >= DANGER_AT:
        return "danger"
    if score >= WARNING_AT:
        return "warning"
    return "safe"


SHORTENERS = {
    "bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "cutt.ly", "rb.gy",
    "s.id", "shorturl.at", "ow.ly", "buff.ly", "tiny.cc", "rebrand.ly",
    "t.ly", "bitly.com", "wa.link", "shorturl.asia", "v.gd", "s.shopee.co.id",
}
SUSPICIOUS_TLDS = {
    "xyz", "top", "click", "link", "tk", "ml", "ga", "cf", "gq", "icu", "buzz",
    "cyou", "monster", "zip", "mov", "rest", "support", "cfd", "sbs", "loan",
    "win", "bid", "vip", "cam", "work", "men", "stream", "download", "country",
}
FREE_HOSTS = {
    "blogspot.com", "weebly.com", "wixsite.com", "web.app", "firebaseapp.com",
    "pages.dev", "netlify.app", "vercel.app", "glitch.me", "ngrok.io",
    "ngrok-free.app", "trycloudflare.com", "000webhostapp.com", "herokuapp.com",
    "workers.dev", "webflow.io", "carrd.co", "github.io", "myfritz.net",
}
RISKY_EXT = {"apk", "xapk", "apks", "exe", "scr", "bat", "cmd", "msi", "jar", "vbs", "ps1", "iso", "dmg", "lnk"}
ARCHIVE_EXT = {"zip", "rar", "7z", "tar", "gz"}
SECOND_LEVEL = {"co", "go", "ac", "or", "my", "web", "sch", "net", "com"}

# brand -> official registered domains
BRANDS: dict[str, set[str]] = {
    "bca": {"bca.co.id", "klikbca.com"}, "bri": {"bri.co.id"}, "bni": {"bni.co.id"},
    "mandiri": {"bankmandiri.co.id", "livin.id"}, "btn": {"btn.co.id"},
    "cimb": {"cimbniaga.co.id"}, "permata": {"permatabank.com"},
    "jenius": {"jenius.com", "btpn.com"}, "seabank": {"seabank.co.id"},
    "ojk": {"ojk.go.id"}, "bpjs": {"bpjs-kesehatan.go.id", "bpjsketenagakerjaan.go.id"},
    "pajak": {"pajak.go.id"}, "kominfo": {"kominfo.go.id", "komdigi.go.id"},
    "pln": {"pln.co.id"}, "telkomsel": {"telkomsel.com"}, "indihome": {"indihome.co.id"},
    "tokopedia": {"tokopedia.com"}, "shopee": {"shopee.co.id", "shopee.com"},
    "lazada": {"lazada.co.id", "lazada.com"}, "bukalapak": {"bukalapak.com"},
    "blibli": {"blibli.com"}, "traveloka": {"traveloka.com"}, "gojek": {"gojek.com"},
    "gopay": {"gopay.co.id", "gojek.com"}, "dana": {"dana.id"}, "ovo": {"ovo.id"},
    "linkaja": {"linkaja.id"}, "jne": {"jne.co.id"}, "sicepat": {"sicepat.com"},
    "paypal": {"paypal.com"}, "google": {"google.com", "google.co.id"},
    "facebook": {"facebook.com"}, "instagram": {"instagram.com"},
    "whatsapp": {"whatsapp.com", "wa.me"}, "telegram": {"telegram.org", "t.me"},
    "tiktok": {"tiktok.com"}, "netflix": {"netflix.com"},
    "microsoft": {"microsoft.com", "live.com", "office.com"},
    "apple": {"apple.com", "icloud.com"}, "amazon": {"amazon.com"},
}
_BRAND_AFFIXES = (
    "klik", "online", "login", "secure", "mobile", "official", "my", "bank",
    "id", "info", "help", "cs", "care", "update", "verif", "ib", "net",
)
_FUZZY_OK = {"paypay"}  # real services one letter away from a brand
_LEET = str.maketrans({"0": "o", "1": "l", "3": "e", "5": "s", "4": "a"})

URL_KEYWORDS = re.compile(
    r"(login|signin|verif|update|akun|account|secure|hadiah|gratis|klaim|claim|"
    r"undian|bonus|promo|giveaway|apk|konfirmasi|blokir|unlock|wallet|slot|gacor)",
    re.IGNORECASE,
)

_TLDS = (
    r"co\.id|go\.id|ac\.id|or\.id|my\.id|web\.id|sch\.id|"
    r"com|net|org|info|biz|xyz|top|click|link|site|online|store|shop|live|app|io|"
    r"vip|club|win|bet|cam|work|icu|buzz|cc|tk|ml|ga|cf|gq|ly|gl|gd|is|me|id|co"
)
_URL_RE = re.compile(
    r"""(?ix)
    (?<![\w@.])
    (
        (?:https?://|www\.)[^\s<>"']+
      |
        (?:[a-z0-9-]+\.)+(?:""" + _TLDS + r""")(?![a-z])(?:[/:?#][^\s<>"']*)?
    )
    """
)
_TRAILING = ".,;:!?)]}\"'"


def extract_urls(text: str) -> list[str]:
    seen: list[str] = []
    for m in _URL_RE.finditer(text):
        u = m.group(1).rstrip(_TRAILING)
        if u and u not in seen:
            seen.append(u)
    return seen


def registered_domain(host: str) -> str:
    labels = host.split(".")
    if len(labels) >= 3 and labels[-2] in SECOND_LEVEL and len(labels[-1]) == 2:
        return ".".join(labels[-3:])
    return ".".join(labels[-2:])


def _within_one_edit(a: str, b: str) -> bool:
    if a == b:
        return True
    if abs(len(a) - len(b)) > 1:
        return False
    if len(a) == len(b):
        return sum(x != y for x, y in zip(a, b)) <= 1
    short, long_ = (a, b) if len(a) < len(b) else (b, a)
    i = 0
    while i < len(short) and short[i] == long_[i]:
        i += 1
    return short[i:] == long_[i + 1:]


def impersonated_brand(host: str) -> Optional[str]:
    reg = registered_domain(host)
    tokens = [t for t in re.split(r"[.\-_]", host) if t]
    for brand, official in BRANDS.items():
        if reg in official:
            continue
        for raw in tokens:
            norm = raw.translate(_LEET)
            if raw == brand or norm == brand:
                return brand
            if len(brand) >= 6 and brand in norm:
                return brand
            if any(norm in (a + brand, brand + a) for a in _BRAND_AFFIXES):
                return brand
            if len(brand) >= 5 and raw not in _FUZZY_OK and raw != brand and _within_one_edit(raw, brand):
                return brand
    return None


@dataclass
class UrlReport:
    url: str
    risk: int
    status: str
    level: str
    reasons: list[str] = field(default_factory=list)


def analyze_url(raw: str) -> UrlReport:
    raw = raw.strip()
    explicit = bool(re.match(r"(?i)^https?://", raw))
    parsed = urlparse(raw if explicit else "http://" + raw)
    host = (parsed.hostname or "").lower()
    reasons: list[str] = []
    risk = 0

    def add(points: int, why: str) -> None:
        nonlocal risk
        risk += points
        reasons.append(why)

    if not host:
        return UrlReport(raw, 40, "Tautan tidak valid", "warning", ["Format tautan tidak bisa dibaca."])

    reg = registered_domain(host)
    if reg in SHORTENERS or host in SHORTENERS:
        add(22, f"Pemendek URL ({reg}) menyembunyikan tujuan asli tautan.")
    if re.fullmatch(r"\d{1,3}(\.\d{1,3}){3}", host):
        add(40, "Memakai alamat IP, bukan nama domain.")
    if "@" in parsed.netloc:
        add(30, "Mengandung karakter '@' untuk menyamarkan tujuan.")
    if "xn--" in host:
        add(30, "Domain memakai punycode (bisa menyamar sebagai domain lain).")
    tld = host.rsplit(".", 1)[-1]
    if tld in SUSPICIOUS_TLDS:
        add(20, f"Ekstensi domain .{tld} sering dipakai untuk penipuan.")
    if any(host == d or host.endswith("." + d) for d in FREE_HOSTS):
        add(12, "Situs di platform hosting gratis (sering dipakai phishing).")
    if explicit and parsed.scheme == "http":
        add(10, "Tidak memakai HTTPS.")
    if host.count(".") >= 4:
        add(15, "Terlalu banyak subdomain.")
    if host.count("-") >= 2:
        add(10, "Nama domain mengandung banyak tanda hubung.")

    brand = impersonated_brand(host)
    if brand:
        add(45, f"Domain meniru merek '{brand}' tetapi bukan domain resminya.")

    last = parsed.path.rsplit("/", 1)[-1].lower()
    ext = last.rsplit(".", 1)[-1] if "." in last else ""
    if ext in RISKY_EXT:
        add(45, f"Tautan langsung mengunduh file .{ext} (bisa malware).")
    elif ext in ARCHIVE_EXT:
        add(15, f"Tautan mengunduh arsip .{ext}.")
    if re.search(r"\.(pdf|jpe?g|png|docx?|xlsx?)\.(exe|apk|scr|bat)\b", parsed.path.lower()):
        add(30, "Ekstensi ganda menyamarkan file berbahaya.")
    if any(k in parse_qs(parsed.query.lower()) for k in ("redirect", "url", "next", "goto", "return", "link")) and \
            re.search(r"https?(://|%3a%2f%2f)", parsed.query.lower()):
        add(15, "Parameter pengalihan ke situs lain.")

    kw = {m.group(1).lower() for m in URL_KEYWORDS.finditer(host + parsed.path)}
    if kw:
        add(min(25, 10 * len(kw)), "Kata pancingan di tautan: " + ", ".join(sorted(kw)) + ".")
    if len(raw) > 75:
        add(5, "Tautan sangat panjang.")

    risk = min(100, risk)
    level = level_for(risk)
    status = {"danger": "Berbahaya (indikasi phishing/malware)", "warning": "Mencurigakan",
              "safe": "Tidak ada indikasi bahaya"}[level]
    return UrlReport(raw, risk, status, level, reasons)
