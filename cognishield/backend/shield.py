"""Lapisan pertahanan tambahan CogniShield (stdlib only).

1. Domain kognitif: mengenali TAKTIK MANIPULASI (rekayasa sosial) yang dipakai penipu,
   berdasarkan prinsip persuasi dari psikologi sosial (otoritas, urgensi, ketakutan,
   kelangkaan, iming-iming, kerahasiaan, bukti sosial, kedekatan).
2. Konsistensi klaim vs tautan: pesan menyebut sebuah lembaga/merek, tetapi tautannya
   mengarah ke domain lain yang bukan milik lembaga itu.
3. Pertahanan berlapis (defense in depth): hasil tiap lapisan dilaporkan terpisah, dan
   tingkat keyakinan dihitung dari berapa lapisan yang INDEPENDEN saling sepakat.

Semuanya berbasis aturan/heuristik: bukan model pembelajaran mesin dan bukan probabilitas
yang terkalibrasi.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional

from urlcheck import BRANDS, SHORTENERS, registered_domain
from urllib.parse import urlparse

_F = re.IGNORECASE


@dataclass(frozen=True)
class Tactic:
    id: str
    name: str
    principle: str
    weight: int
    pattern: re.Pattern


TACTICS = [
    Tactic("urgency", "Tekanan waktu", "Urgensi: korban dipaksa memutuskan sebelum sempat berpikir.", 16,
           re.compile(r"\b(segera|sekarang\s+juga|detik\s+ini|dalam\s+\d+\s*(jam|menit|hari)|1x24|24\s*jam|batas\s+waktu|"
                      r"paling\s+lambat|jangan\s+(sampai\s+)?terlambat|buruan|urgent|immediately|right\s+now)\b", _F)),
    Tactic("authority", "Mengaku otoritas", "Otoritas: pengirim berpura-pura sebagai pihak yang harus ditaati.", 14,
           re.compile(r"\b(polri|polisi|kepolisian|penyidik|kejaksaan|pengadilan|bareskrim|kominfo|komdigi|ojk|petugas|"
                      r"pihak\s+(bank|bca|bri|bni|mandiri|kurir|jne|polisi)|customer\s+service|admin\s+resmi|"
                      r"tim\s+(keamanan|security|resmi)|kementerian|bpjs|dirjen)\b", _F)),
    Tactic("fear", "Rasa takut / ancaman", "Ketakutan: ancaman kerugian atau hukuman melumpuhkan nalar.", 22,
           re.compile(r"(diblokir|dibekukan|ditangkap|dipenjara|didenda|denda|pidana|disebar(kan)?|dibocorkan|diretas|"
                      r"dihack|disita|dicabut|ditutup|dilaporkan|terlibat\s+(kasus|pencucian)|suspended|blocked)", _F)),
    Tactic("greed", "Iming-iming hadiah / untung", "Imbalan: janji keuntungan besar memancing keserakahan.", 16,
           re.compile(r"(menang|pemenang|hadiah|gratis|bonus|cashback|cuan|passive\s+income|jackpot|maxwin|"
                      r"dijamin\s+(untung|profit|cair)|profit\s+\d+|gaji\s+\w*\s*(tinggi|besar)|jutaan)", _F)),
    Tactic("scarcity", "Kelangkaan buatan", "Kelangkaan: 'terbatas' membuat korban takut kehilangan kesempatan.", 10,
           re.compile(r"(terbatas|hanya\s+hari\s+ini|sisa\s+\d+\s*(slot|kuota|unit)|stok\s+terakhir|last\s+chance|"
                      r"limited\s+(time|offer)|kuota\s+hampir)", _F)),
    Tactic("secrecy", "Isolasi / kerahasiaan", "Isolasi: korban diminta menyembunyikan agar tidak ada yang menyadarkan.", 20,
           re.compile(r"(jangan\s+(bilang|kasih\s+tahu|beri\s+tahu|beritahu|cerita)|rahasiakan|hanya\s+kita\s+berdua|"
                      r"pindah\s+(chat\s+)?(ke\s+)?(whatsapp|wa|telegram))", _F)),
    Tactic("social_proof", "Bukti sosial palsu", "Bukti sosial: 'banyak yang sudah berhasil' mengurangi kewaspadaan.", 8,
           re.compile(r"(ribuan\s+(orang|member|user)|ratusan\s+(orang|member)|sudah\s+terbukti|testimoni|"
                      r"member\s+(kami|vip)|banyak\s+yang\s+(sudah\s+)?(berhasil|cair|wd|withdraw))", _F)),
    Tactic("pretext", "Kedekatan / belas kasihan", "Pretext: cerita darurat atau nomor 'baru' untuk memancing empati.", 12,
           re.compile(r"(nomor\s+baru|hp\s+(lama\s+)?(rusak|hilang)|darurat|musibah|kecelakaan|rumah\s+sakit|"
                      r"tolong\s+(bantu|transfer)|tolong\s+kirim(kan)?\s+(uang|pulsa|dana))", _F)),
]

# Permintaan tindakan berisiko (bukan taktik, tetapi syarat agar taktik berbahaya).
_RISKY_ACTION = re.compile(
    r"((klik|buka|kunjungi|akses)\s+(\w+\s+){0,2}(tautan|link|url|situs|website)|"
    r"\b(transfer|setor|deposit|top\s*up|topup|bayar)\b|kirim(kan)?\s+(uang|dana|kode|otp|pin)|"
    r"(unduh|download|install|pasang)\s+(\w+\s+){0,3}(apk|aplikasi|file)|"
    r"(hubungi|telepon)\s+(nomor|kami|cs)|scan\s+(qr|barcode)|(isi|lengkapi)\s+(data|formulir))", _F)


def analyze_tactics(text: str) -> dict:
    found = []
    for t in TACTICS:
        m = t.pattern.search(text)
        if m:
            ev = re.sub(r"\s+", " ", m.group(0)).strip()
            found.append({"id": t.id, "name": t.name, "principle": t.principle, "evidence": ev[:40], "weight": t.weight})
    action = bool(_RISKY_ACTION.search(text))
    score = sum(f["weight"] for f in found)
    if action and len(found) >= 2:
        score += 15
    return {"tactics": found, "risky_action": action, "score": min(100, score)}


# Lembaga/merek yang sering dicatut. Sengaja tanpa kata umum (mis. 'dana') atau
# platform sosial, supaya pesan biasa tidak salah ditandai.
_CLAIM_BRANDS = (
    "bca", "bri", "bni", "mandiri", "btn", "cimb", "permata", "jenius", "seabank", "ojk", "bpjs",
    "kominfo", "pln", "telkomsel", "indihome", "tokopedia", "shopee", "lazada", "bukalapak",
    "blibli", "gojek", "gopay", "ovo", "linkaja", "jne", "sicepat", "paypal",
)
_BRAND_RE = re.compile(r"\b(" + "|".join(_CLAIM_BRANDS) + r")\b", _F)


def _host(u: str) -> str:
    raw = u if re.match(r"(?i)^https?://", u) else "http://" + u
    return (urlparse(raw).hostname or "").lower()


def claim_link_mismatch(text: str, urls: list[str]) -> list[dict]:
    """Pesan menyebut merek X tetapi tidak satu pun tautan milik X."""
    if not urls:
        return []
    hosts = [(_host(u)) for u in urls]
    regs = [registered_domain(h) for h in hosts if h]
    out = []
    for brand in sorted({m.group(1).lower() for m in _BRAND_RE.finditer(text)}):
        official = BRANDS.get(brand, set())
        if any(r in official for r in regs):
            continue
        hidden = all(r in SHORTENERS for r in regs)
        out.append({"brand": brand, "domains": sorted(set(regs)), "hidden": hidden})
    return out


def confidence_from_layers(layers: list[dict], risky: bool) -> tuple[str, dict]:
    """Tingkat keyakinan = seberapa banyak lapisan independen yang sepakat."""
    voters = [l for l in layers if l["voter"] and l["active"]]
    fired = sum(1 for l in voters if l["fired"])
    total = len(voters)
    if not risky:
        label = "tidak_ada_sinyal" if fired == 0 else "sinyal_lemah"
    elif fired >= 3:
        label = "tinggi"
    elif fired == 2:
        label = "sedang"
    else:
        label = "rendah"
    return label, {"fired": fired, "total": total}