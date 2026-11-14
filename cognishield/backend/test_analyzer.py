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
