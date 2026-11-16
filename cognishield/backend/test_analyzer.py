"""Run:  python test_analyzer.py   (or: pytest)"""
import analyzer as a

# (text, expected primary category, minimum level)
THREATS = [
    ("Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun", "phishing", "danger"),
    ("Pihak BCA meminta kode OTP Anda sekarang juga untuk membatalkan transaksi", "credential", "danger"),
    ("Selamat anda menang undian, klik https://bit.ly/hadiah-gratis untuk klaim hadiah", "prize_scam", "danger"),
    ("Halo, maaf kode verifikasi WhatsApp salah kirim ke nomor kamu, tolong kirimkan kodenya ya", "account_takeover", "danger"),
    ("Surat tilang elektronik Anda: unduh file TILANG_2026.apk lalu install", "malware", "danger"),
    ("Join grup VIP trading kami, profit 10% per hari dijamin! deposit 100rb saja https://t.me/vipcuan", "investment", "danger"),
    ("Bocoran slot gacor hari ini maxwin! Bonus new member 100% https://slot88-gacor.xyz", "gambling", "danger"),
    ("Pinjaman cepat tanpa jaminan cair 5 menit, transfer biaya admin dulu Rp200.000", "loan", "danger"),
    ("Lowongan kerja online, gaji Rp 500 ribu per hari, tanpa pengalaman. Bayar biaya pendaftaran Rp150.000", "job_scam", "danger"),
    ("Kami dari Polri. Nomor Anda terlibat pencucian uang. Segera hubungi penyidik atau rekening akan diblokir", "impersonation", "warning"),
    ("Paket Anda tertahan, alamat tidak lengkap. Konfirmasi di https://jne-track.top/cek", "courier", "warning"),
    ("Halo mah ini nomor baru aku, hp lama rusak. Tolong transfer dulu 2 juta ke rekening ini, urgent ya jangan bilang papa", "family", "danger"),
    ("Saya punya video pribadi kamu. Bayar 500 USD bitcoin dalam 24 jam atau saya sebar ke semua kontak", "extortion", "danger"),
    ("PERINGATAN: komputer Anda terinfeksi virus! Hubungi CS Microsoft 081234567890 dan pasang AnyDesk", "tech_support", "danger"),
    ("Barang ready kak, transfer DP dulu ya, lanjut chat di WhatsApp aja", "marketplace", "danger"),
    ("HEBOH!!! Terungkap rahasia besar yang disembunyikan media! Tolong share ke 10 grup, 100% pasti terjadi!", "hoax", "danger"),
    ("https://example.xyz/download/update.apk", "unsafe_link", "danger"),
    ("http://klikbca-verifikasi.xyz/login", "unsafe_link", "danger"),
]

SAFE = [
    "Besok rapat kelompok jam 10 di perpustakaan ya",
    "Kode OTP Anda 482913. Jangan berikan kode ini kepada siapa pun.",
    "Token listrik Anda: 1234 5678 9012 3456 7890",
    "Bro, nanti malam futsal jam 8, jangan telat",
    "Pesanan Anda sudah dikirim. Lacak di https://shopee.co.id/user/purchase",
    "Selamat ulang tahun ya! Semoga sehat selalu",
    "Tolong kirim tugas laporan ke email dosen sebelum jam 5",
    "Menurut BMKG, hujan lebat diperkirakan terjadi di Tangerang pada Sabtu sore.",
    "Slot parkir di lantai 2 sudah penuh",
    "Mama transfer uang jajan ya nak, sudah masuk",
    "https://www.bca.co.id/id/",
    "https://www.google.com/search?q=flutter",
    "Promo gratis ongkir hanya hari ini di aplikasi, bayar lewat GoPay",
    "Tolong bantu kirim tugas laporan ke email dosen sebelum jam 5",
    "Transfer ke rekening BCA saya ya, rincian ada di lampiran",
]

ORDER = {"safe": 0, "warning": 1, "danger": 2}


def test_threats_detected():
    bad = []
    for text, cat, min_level in THREATS:
        r = a.analyze_auto(text)
        ids = [c["id"] for c in r.categories]
        if ORDER[r.level] < ORDER[min_level] or cat not in ids:
            bad.append((text[:50], r.level, r.risk, ids))
    assert not bad, bad


def test_normal_messages_stay_safe():
    flagged = [(t[:50], a.analyze_auto(t).level, a.analyze_auto(t).risk) for t in SAFE if a.analyze_auto(t).level != "safe"]
    assert not flagged, flagged


def test_primary_category_on_auto():
    r = a.analyze_auto("Pihak BCA meminta kode OTP Anda sekarang juga untuk membatalkan transaksi")
    assert r.primary == "credential" and r.title.startswith("Waspada")


def test_mode_wrappers():
    assert a.analyze_notification("Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun").level == "danger"
    assert a.analyze_propaganda("HEBOH!!! rahasia besar disembunyikan media! share ke 10 grup 100% pasti!").level == "danger"
    assert a.analyze_url_only("bukan tautan").kind == "url"


def _bold(s):
    """Convert ASCII letters to bold sans-serif unicode (a scammer trick to dodge filters)."""
    return "".join(
        chr(0x1D5D4 + ord(c) - 65) if "A" <= c <= "Z" else chr(0x1D5EE + ord(c) - 97) if "a" <= c <= "z" else c
        for c in s
    )


def test_fancy_unicode_is_normalized():
    plain = a.analyze_auto("Akun Anda dibekukan, segera verifikasi akun")
    fancy = a.analyze_auto(_bold("Akun Anda dibekukan, segera verifikasi akun"))
    assert plain.level != "safe" and fancy.risk == plain.risk


def test_otp_request_vs_otp_delivery():
    assert a.analyze_auto("Tolong berikan kode OTP kamu sekarang").level != "safe"
    assert a.analyze_auto("Kode OTP Anda 482913. Jangan berikan kode ini kepada siapa pun.").level == "safe"


def test_brand_impersonation_and_official():
    assert a.analyze_url("http://klikbca-verifikasi.xyz/login").level == "danger"
    assert a.analyze_url("https://tokopedla.com/login").level != "safe"
    assert a.analyze_url("https://www.bca.co.id/id/").level == "safe"
    assert a.analyze_url("https://paypay.ne.jp/").level == "safe"


def test_extract_urls():
    urls = a.extract_urls("Klik bit.ly/abc, atau https://contoh.com/x?y=1. Terima kasih")
    assert "bit.ly/abc" in urls and "https://contoh.com/x?y=1" in urls


def _layer(r, lid):
    return next(l for l in r.layers if l["id"] == lid)


def test_cognitive_tactics_detected():
    r = a.analyze_auto("Halo mah ini nomor baru aku, hp lama rusak. Tolong transfer dulu 2 juta, urgent ya jangan bilang papa")
    ids = {t["id"] for t in r.tactics}
    assert {"urgency", "secrecy", "pretext"} <= ids, ids
    assert r.cognitive_score >= 40 and _layer(r, "cognitive")["fired"]
    plain = a.analyze_auto("Besok rapat kelompok jam 10 di perpustakaan ya")
    assert plain.tactics == [] and not _layer(plain, "cognitive")["fired"]


def test_claim_link_mismatch():
    bad = a.analyze_auto("Pihak BCA meminta Anda login di https://bca-aman.xyz/verif sekarang juga")
    assert _layer(bad, "consistency")["fired"] and bad.level == "danger"
    assert any("bukan domain resmi" in x for x in bad.reasons)
    ok = a.analyze_auto("Pesanan Anda sudah dikirim. Lacak di https://shopee.co.id/user/purchase")
    assert not _layer(ok, "consistency")["fired"] and ok.level == "safe"
    hidden = a.analyze_auto("Info dari BCA cek di bit.ly/abc123")
    assert _layer(hidden, "consistency")["fired"]


def test_confidence_follows_layer_agreement():
    hi = a.analyze_auto("Pihak BCA meminta kode OTP Anda sekarang juga. Login di https://bca-aman.xyz/verif")
    assert hi.confidence == "tinggi" and hi.agreement["fired"] >= 3
    safe = a.analyze_auto("Besok rapat kelompok jam 10 di perpustakaan ya")
    assert safe.confidence == "tidak_ada_sinyal" and safe.agreement["fired"] == 0
    # satu lapisan saja yang berbunyi -> keyakinan tidak boleh 'tinggi'
    for txt in ("https://example.xyz/download/update.apk",
                "Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun",
                "Selamat anda menang undian, klik https://bit.ly/hadiah-gratis untuk klaim hadiah"):
        r = a.analyze_auto(txt)
        n = r.agreement["fired"]
        assert r.confidence == ("tinggi" if n >= 3 else "sedang" if n == 2 else "rendah"), (txt, r.confidence, n)


def test_layers_report_and_ml_inactive_by_default():
    r = a.analyze_auto("Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun")
    ids = [l["id"] for l in r.layers]
    assert ids == ["normalize", "rules", "cognitive", "url", "consistency", "virustotal", "ml"], ids
    assert _layer(r, "ml")["active"] is False and r.engine == "rules"
    a.register_text_model(lambda t: 0.9)
    try:
        r2 = a.analyze_auto("HEBOH!!! rahasia besar disembunyikan media, share ke 10 grup!" + " x" * 20)
        assert _layer(r2, "ml")["active"] and r2.engine == "rules+ml"
    finally:
        a.register_text_model(None)


def test_manipulation_only_needs_many_tactics_and_action():
    import shield
    assert len(shield.analyze_tactics("Segera hubungi petugas, hadiah terbatas, rahasiakan ini, lalu transfer ya")["tactics"]) >= 4
    assert shield.analyze_tactics("Mama transfer uang jajan ya nak")["tactics"] == []


def _fake_vt(stats=None, known=True, analysis_done=True, calls=None):
    """Fake VirusTotal HTTP layer: (method, url, headers, body) -> (status, dict)."""
    def http(method, url, headers, body):
        if calls is not None:
            calls.append((method, url))
        assert headers.get("x-apikey") == "KEY"
        if method == "GET" and "/urls/" in url:
            if known:
                return 200, {"data": {"attributes": {"last_analysis_stats": stats}}}
            return 404, {}
        if method == "POST":
            return 200, {"data": {"id": "analysis-1"}}
        if method == "GET" and "/analyses/" in url:
            return 200, {"data": {"attributes": {"status": "completed" if analysis_done else "queued", "stats": stats}}}
        return 500, {}
    return http


def _with_vt(http, fn, **kw):
    import analyzer as A
    from vt import VirusTotal
    client = VirusTotal("KEY", http=http, sleep=lambda s: None, **kw)
    A.register_url_reputation(client.check)
    try:
        return fn(A)
    finally:
        A.register_url_reputation(None)


def test_virustotal_confirms_unsafe_link_even_with_calm_text():
    calm = "Halo, ini fotonya ya http://foto-keluarga-2024.example.net/album"
    base = a.analyze_auto(calm)
    stats = {"malicious": 9, "suspicious": 1, "harmless": 50, "undetected": 20}
    r = _with_vt(_fake_vt(stats), lambda A: A.analyze_auto(calm))
    assert base.level == "safe"
    assert r.level == "danger" and r.risk >= 90, (r.level, r.risk)
    assert r.urls[0].vt["malicious"] == 9
    assert _layer(r, "virustotal")["active"] and _layer(r, "virustotal")["fired"]
    assert any("VirusTotal" in x for x in r.reasons)


def test_virustotal_clean_never_lowers_risk():
    msg = "Selamat! Anda menang undian, klik http://bit.ly/hadiah-bca sekarang"
    base = a.analyze_auto(msg)
    stats = {"malicious": 0, "suspicious": 0, "harmless": 70, "undetected": 10}
    r = _with_vt(_fake_vt(stats), lambda A: A.analyze_auto(msg))
    assert r.risk >= base.risk and r.level == base.level


def test_virustotal_down_or_no_key_falls_back_to_local():
    msg = "Halo, ini linknya http://foto-keluarga-2024.example.net/album"
    def boom(*a):
        return 0, {}
    r = _with_vt(boom, lambda A: A.analyze_auto(msg))
    assert r.level == "safe" and not _layer(r, "virustotal")["active"]
    r2 = a.analyze_auto(msg)
    assert not _layer(r2, "virustotal")["active"]


def test_virustotal_new_url_submit_then_pending_and_cache():
    calls = []
    stats = {"malicious": 3, "suspicious": 0, "harmless": 60, "undetected": 5}
    http = _fake_vt(stats, known=False, analysis_done=True, calls=calls)
    from vt import VirusTotal
    c = VirusTotal("KEY", http=http, sleep=lambda s: None)
    r1 = c.check("http://baru.example.org/x")
    assert r1["status"] == "found" and r1["malicious"] == 3
    n = len(calls)
    c.check("http://baru.example.org/x")
    assert len(calls) == n, "second lookup must come from cache"
    pend = VirusTotal("KEY", http=_fake_vt(stats, known=False, analysis_done=False), sleep=lambda s: None)
    assert pend.check("http://lain.example.org")["status"] == "pending"


def test_virustotal_rate_limit_is_respected():
    from vt import VirusTotal
    stats = {"malicious": 0, "suspicious": 0, "harmless": 10, "undetected": 0}
    c = VirusTotal("KEY", http=_fake_vt(stats), sleep=lambda s: None, per_minute=2)
    assert c.check("http://a.example.org")["status"] == "found"
    assert c.check("http://b.example.org")["status"] == "found"
    assert c.check("http://c.example.org")["status"] == "unavailable"


if __name__ == "__main__":
    fns = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for f in fns:
        try:
            f()
            print("ok  ", f.__name__)
        except AssertionError as e:
            failed += 1
            print("FAIL", f.__name__, "->", e)
    print(f"\n{len(fns) - failed}/{len(fns)} tests passed")
    raise SystemExit(1 if failed else 0)