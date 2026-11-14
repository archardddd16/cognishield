"""CogniShield analysis engine (rule-based + heuristics, stdlib only).

One engine scans any text (message, notification, pasted news, link) for many
kinds of harm. A real ML model can be plugged in with `register_text_model`.
"""
from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from typing import Callable, Optional

from rules_account import RULES as _R1
from rules_fraud import RULES as _R2
from rules_social import RULES as _R3
from urlcheck import (  # noqa: F401  (re-exported for callers/tests)
    DANGER_AT,
    WARNING_AT,
    UrlReport,
    analyze_url,
    extract_urls,
    level_for,
)

CATEGORY_NAMES = {
    "phishing": "Phishing / Pencurian Akun",
    "credential": "Pencurian OTP & Data Pribadi",
    "account_takeover": "Pembajakan Akun",
    "malware": "Malware / APK Berbahaya",
    "prize_scam": "Penipuan Hadiah & Bansos",
    "investment": "Penipuan Investasi / Kripto",
    "gambling": "Judi Online",
    "loan": "Pinjol Ilegal / Penipuan Pinjaman",
    "job_scam": "Penipuan Lowongan Kerja",
    "impersonation": "Pencatutan Lembaga / Aparat",
    "courier": "Penipuan Paket / Kurir",
    "family": "Penipuan Nomor Baru / Keluarga",
    "extortion": "Pemerasan / Ransomware",
    "tech_support": "Penipuan Layanan Palsu",
    "marketplace": "Penipuan Jual-Beli",
    "romance": "Penipuan Asmara / Warisan",
    "hoax": "Hoaks / Propaganda",
    "unsafe_link": "Tautan Berbahaya",
}

ADVICE = {
    "phishing": "Jangan klik tautan atau login lewat pesan ini. Buka aplikasi resmi atau ketik sendiri alamat situsnya.",
    "credential": "Jangan pernah membagikan OTP, PIN, CVV, atau password kepada siapa pun, termasuk yang mengaku petugas bank.",
    "account_takeover": "Jangan kirim kode verifikasi ke siapa pun. Aktifkan verifikasi dua langkah dan keluarkan perangkat asing dari akunmu.",
    "malware": "Jangan memasang file .apk/.exe dari chat atau tautan. Pasang aplikasi hanya dari Play Store atau App Store.",
    "prize_scam": "Hadiah yang tiba-tiba datang hampir pasti penipuan. Jangan klik dan jangan bayar biaya apa pun.",
    "investment": "Tidak ada investasi yang menjamin untung pasti. Cek legalitas di ojk.go.id atau hubungi OJK 157 sebelum menyetor uang.",
    "gambling": "Judi online ilegal dan sering dipakai untuk mencuri data & uang. Jangan deposit; laporkan ke aduankonten.id.",
    "loan": "Pinjol resmi tidak meminta biaya di muka. Cek daftar pinjol berizin di ojk.go.id.",
    "job_scam": "Pekerjaan sah tidak meminta biaya pendaftaran atau modal. Waspadai tugas 'like & subscribe' berbayar.",
    "impersonation": "Polisi, bank, dan instansi tidak menyelesaikan kasus lewat chat atau transfer. Hubungi lewat nomor resmi mereka.",
    "courier": "Cek status paket hanya di aplikasi/situs resmi ekspedisi. Jangan klik tautan atau pasang file dari 'kurir'.",
    "family": "Telepon langsung keluarga/teman lewat nomor lama sebelum mentransfer uang.",
    "extortion": "Jangan bayar dan jangan balas. Simpan bukti, blokir pengirim, dan laporkan ke patrolisiber.id atau polisi.",
    "tech_support": "Perusahaan teknologi tidak menghubungimu soal virus lewat chat. Jangan pasang AnyDesk/TeamViewer atas permintaan orang asing.",
    "marketplace": "Bertransaksi hanya di dalam aplikasi marketplace. Jangan transfer DP ke penjual yang mengajak pindah chat.",
    "romance": "Jangan kirim uang kepada orang yang hanya kamu kenal online, apa pun alasannya.",
    "hoax": "Jangan sebarkan. Cek ke sumber resmi atau situs cek fakta (turnbackhoax.id, cekfakta.com).",
    "unsafe_link": "Jangan buka tautan ini dan jangan masukkan data pribadi apa pun.",
}
SAFE_ADVICE = "Tidak ditemukan indikasi ancaman, tetapi tetap waspada. Pemeriksaan ini berbasis pola, bukan jaminan."

ALL_CATEGORIES = set(CATEGORY_NAMES) | {"pressure"}
CREDIBLE = re.compile(
    r"\b(menurut|dikutip\s+dari|sumber:?|rilis\s+resmi)\s+(kompas|antara|tempo|detik|bmkg|who|kemenkes|"
    r"kementerian|bps|bnpb|kominfo|komdigi|reuters|ap\b)",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class Rule:
    category: str
    weight: int
    reason: str
    pattern: re.Pattern


RULES = [
    Rule(c, w, r, re.compile(p, re.IGNORECASE | re.DOTALL))
    for c, w, r, p in (*_R1, *_R2, *_R3)
]

TextModel = Callable[[str], float]
_text_model: Optional[TextModel] = None


def register_text_model(fn: Optional[TextModel]) -> None:
    """Plug in an ML model: fn(text) -> probability (0..1) that text is hoax/propaganda."""
    global _text_model
    _text_model = fn


@dataclass
class Analysis:
    kind: str
    risk: int
    level: str
    label: str
    title: str
    reasons: list[str]
    advice: str
    urls: list[UrlReport]
    categories: list[dict] = field(default_factory=list)  # [{id, name, score}]
    primary: Optional[str] = None
    engine: str = "rules"


_ZERO_WIDTH = re.compile("[​-‏‪-‮⁠﻿]")


def normalize(text: str) -> str:
    """Fold fancy unicode (bold/full-width letters) to plain text and drop invisible chars."""
    return _ZERO_WIDTH.sub("", unicodedata.normalize("NFKC", text)).strip()


def _score_rules(text: str, allow: Optional[set[str]]) -> dict[str, list]:
    per: dict[str, list] = {}
    for r in RULES:
        if allow is not None and r.category not in allow:
            continue
        if r.pattern.search(text):
            ent = per.setdefault(r.category, [0, []])
            ent[0] += r.weight
            ent[1].append(r.reason if r.weight > 0 else "(+) " + r.reason)
    for ent in per.values():
        ent[0] = max(0, min(100, ent[0]))
    return per


def _label(kind: str, level: str, primary: Optional[str]) -> str:
    name = CATEGORY_NAMES.get(primary or "", "")
    if level == "danger":
        if primary == "hoax":
            return "Terindikasi Hoaks / Propaganda"
        if primary == "unsafe_link":
            return "Tautan Berbahaya (indikasi phishing/malware)"
        return f"Terindikasi {name}"
    if level == "warning":
        if primary == "hoax":
            return "Perlu Diverifikasi"
        if primary == "unsafe_link":
            return "Tautan Mencurigakan"
        return f"Mencurigakan: {name}"
    return {
        "url": "Tidak ada indikasi bahaya",
        "propaganda": "Tidak Terindikasi Hoaks",
    }.get(kind, "Tidak ada indikasi ancaman")


def _analyze(text: str, kind: str, allow: Optional[set[str]]) -> Analysis:
    text = normalize(text)
    per = _score_rules(text, allow)

    # extra pressure signals: shouting and exclamation marks
    if allow is None or "pressure" in allow:
        ent = per.setdefault("pressure", [0, []])
        letters = [c for c in text if c.isalpha()]
        if len(letters) >= 20 and sum(c.isupper() for c in letters) / len(letters) > 0.5:
            ent[0] += 8
            ent[1].append("Terlalu banyak HURUF KAPITAL.")
        if text.count("!") >= 3:
            ent[0] += 6
            ent[1].append("Tanda seru berlebihan.")

    if "hoax" in per:
        if CREDIBLE.search(text):
            per["hoax"][0] = max(0, per["hoax"][0] - 15)
            per["hoax"][1].append("(+) Mencantumkan sumber yang kredibel.")
    if _text_model is not None and len(text) >= 30 and (allow is None or "hoax" in allow):
        ml = round(_text_model(text) * 100)
        ent = per.setdefault("hoax", [0, []])
        ent[0] = round((ent[0] + ml) / 2)
        ent[1].append(f"Model bahasa memberi skor {ml}/100.")

    urls = [analyze_url(u) for u in extract_urls(text)]
    worst = max(urls, key=lambda u: u.risk) if urls else None

    threats = sorted(
        ((c, e[0]) for c, e in per.items() if c not in ("pressure", "unsafe_link") and e[0] >= 15),
        key=lambda x: -x[1],
    )
    top = threats[0][1] if threats else 0
    second = threats[1][1] if len(threats) > 1 else 0
    press = per.get("pressure", [0, []])[0]
    risk = top + round(0.35 * second)
    if top >= 20:
        risk += round(0.6 * min(press, 40))
    risk = min(100, risk)

    primary = threats[0][0] if threats else None
    if worst is not None:
        if top >= 20 and worst.risk >= 20:
            risk = min(100, risk + 5)
        a, b = risk, worst.risk
        risk = min(100, max(a, b) + round(0.3 * min(a, b)))
        if worst.risk >= WARNING_AT:
            per["unsafe_link"] = [worst.risk, list(worst.reasons)]
            if worst.risk > top:
                primary = "unsafe_link"

    level = level_for(risk)
    cats = [(c, e[0]) for c, e in per.items() if c != "pressure" and e[0] >= 15]
    cats.sort(key=lambda x: -x[1])
    categories = [{"id": c, "name": CATEGORY_NAMES[c], "score": s} for c, s in cats[:5]]

    reasons: list[str] = []
    order = [c for c, _ in cats] + (["pressure"] if press > 0 and top >= 20 else [])
    for c in order:
        for r in per[c][1]:
            if r not in reasons:
                reasons.append(r)
    if kind == "url" and worst is not None and not reasons:
        reasons = list(worst.reasons)
    reasons = reasons[:8]

    if level == "safe":
        primary = None
        title = "Tautan Tampak Aman" if kind == "url" else "Pesan Tampak Aman"
        advice = SAFE_ADVICE
    else:
        name = CATEGORY_NAMES.get(primary or "", "Ancaman")
        title = f"Waspada: {name}"
        advice = ADVICE.get(primary or "", SAFE_ADVICE)
        if level == "warning":
            advice = "Berhati-hatilah. " + advice

    return Analysis(kind, risk, level, _label(kind, level, primary), title, reasons, advice,
                    urls, categories, primary, "rules+ml" if _text_model else "rules")


def analyze_auto(text: str) -> Analysis:
    """Scan anything: message, notification, news text, or a bare link."""
    return _analyze(text, "auto", None)


def analyze_notification(text: str) -> Analysis:
    return _analyze(text, "notification", ALL_CATEGORIES - {"hoax"})


def analyze_propaganda(text: str) -> Analysis:
    return _analyze(text, "propaganda", {"hoax", "pressure"})


def analyze_url_only(text: str) -> Analysis:
    a = _analyze(text, "url", {"unsafe_link"})
    if not a.urls:  # input is a bare host/path that the extractor did not recognise
        rep = analyze_url(text.strip())
        a.urls = [rep]
        a.risk, a.level = rep.risk, rep.level
        a.label = rep.status
        a.title = rep.status
        a.reasons = list(rep.reasons)
        if rep.level != "safe":
            a.primary = "unsafe_link"
            a.categories = [{"id": "unsafe_link", "name": CATEGORY_NAMES["unsafe_link"], "score": rep.risk}]
            a.advice = ADVICE["unsafe_link"]
        else:
            a.advice = SAFE_ADVICE
    return a
