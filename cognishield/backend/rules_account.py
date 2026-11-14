"""Detection rules, part 1: account theft, credentials, malware, prizes.

Each rule: (category, weight, reason, regex). Negative weight = reassuring signal.
"""

RULES = [
    # ---- phishing -------------------------------------------------------
    ("phishing", 28, "Mengancam akun/rekening diblokir atau dibekukan.",
     r"(akun|account|rekening|kartu|e-?wallet|dompet).{0,40}(diblokir|dibekukan|ditangguhkan|dinonaktifkan|dibatasi|ditutup|suspended|locked|disabled|restricted|limited|blocked)"),
    ("phishing", 20, "Meminta Anda memverifikasi/memperbarui akun atau data.",
     r"(verifikasi|verify|konfirmasi|confirm|perbarui|update|aktivasi|validasi|reactivate|aktifkan).{0,30}(akun|account|data|identitas|rekening|kartu|password|kata\s+sandi|sekarang|segera|now)"),
    ("phishing", 25, "Klaim ada aktivitas login mencurigakan.",
     r"(aktivitas|login|masuk|sign[-\s]?in|akses).{0,30}(mencurigakan|tidak\s+dikenal|perangkat\s+baru|suspicious|unusual|unauthorized|tidak\s+sah)"),
    ("phishing", 25, "Mengatakan password/akun akan kedaluwarsa.",
     r"(password|kata\s+sandi|akun|account).{0,30}(kedaluwarsa|kadaluarsa|expired|akan\s+habis|expires?|segera\s+berakhir)"),
    ("phishing", 22, "Modus kenaikan limit kartu/kuota.",
     r"(naik|kenaikan|upgrade|tambah)\w*\s+(limit|plafon|kuota)"),
    ("phishing", 18, "Tagihan/pembayaran gagal yang memancing klik.",
     r"(tagihan|invoice|pembayaran|payment|transaksi).{0,30}(gagal|failed|tertunda|pending|jatuh\s+tempo|overdue|ditolak)"),
    ("phishing", 22, "Mengklaim ada transaksi/login yang bukan Anda.",
     r"(transaksi|pembelian|login|penarikan).{0,30}(tidak\s+anda\s+(kenali|lakukan)|bukan\s+anda|tidak\s+dikenal)"),
    ("phishing", 15, "Meminta Anda login/masuk lewat tautan.",
     r"(login|masuk|sign[-\s]?in|log\s+in).{0,25}(tautan|link|di\s+sini|disini|here|berikut|below|url)"),

    # ---- credential (OTP / PIN / personal data) -------------------------
    ("credential", 22, "Menyebut kode/PIN rahasia.",
     r"\b(otp|kode\s+(verifikasi|rahasia|keamanan|sms|otp)|one[-\s]?time\s+(password|code)|pin|cvv|cvc|m-?pin|passcode|kata\s+sandi|password)\b"),
    ("credential", 38, "Meminta Anda memberikan OTP/PIN/password.",
     r"(minta|meminta|berikan|kirim|kirimkan|sebutkan|bagikan|beritahu|beritahukan|sebut|send|share|provide|reply\s+with|give\s+me).{0,40}(otp|kode(?!\s+(booking|promo|pos|bayar|pembayaran|referral|voucher|diskon|produk|barang|akses|undangan))|pin\b|password|kata\s+sandi|cvv|passcode|code)"),
    ("credential", 28, "Meminta data pribadi (KTP/NIK/kartu).",
     r"(kirim|berikan|upload|unggah|foto|fotokan|lampirkan|send|submit).{0,25}(ktp|nik\b|kartu\s+keluarga|selfie|kartu\s+kredit|kartu\s+atm|paspor|passport|nomor\s+kartu|card\s+number)"),
    ("credential", 25, "Meminta data pribadi lewat formulir.",
     r"(nomor\s+kartu|card\s+number|nomor\s+rekening|nama\s+ibu\s+kandung|tanggal\s+lahir|ssn).{0,40}(isi|masukkan|lengkapi|submit|enter|fill)"),
    ("credential", -45, "Pesan ini mengirim kode OTP (bukan memintanya).",
     r"\b(otp|kode|code|pin|token)\b\D{0,30}\d{4,8}\b"),
    ("credential", -25, "Pesan OTP resmi biasanya melarang membagikan kode.",
     r"(jangan|never|do\s+not|don'?t).{0,30}(bagikan|berikan|beritahu|beri\s+tahu|sebarkan|share|give|tell|disclose).{0,50}(kode|otp|pin|code|siapa\s?pun|anyone|orang\s+lain)"),

    # ---- account takeover ----------------------------------------------
    ("account_takeover", 40, "Pola pembajakan akun: 'kode verifikasi salah kirim'.",
     r"(salah\s+kirim|salah\s+masuk|nyasar|terkirim\s+ke\s+nomor\s+(anda|kamu|mu)|masuk\s+ke\s+nomor\s+(anda|kamu|mu)).{0,60}(kode|otp)|(kode|otp).{0,60}(salah\s+kirim|nyasar|salah\s+masuk|terkirim\s+ke\s+nomor)"),
    ("account_takeover", 30, "Klaim akun diretas / diambil alih.",
     r"(akun|account|whatsapp|wa|instagram|facebook).{0,30}(diretas|dibobol|hacked|compromised|diambil\s+alih|dibajak|takeover)"),
    ("account_takeover", 25, "Meminta menautkan perangkat atau scan QR (bisa membajak akun).",
     r"(tautkan|hubungkan|link|scan|pindai|pairing)\w*.{0,25}(perangkat|device|qr|whatsapp\s+web|kode\s+qr)"),
    ("account_takeover", 20, "Meminta menonaktifkan/mereset verifikasi dua langkah.",
     r"(verifikasi\s+(dua|2)\s+langkah|two[-\s]?factor|2fa).{0,40}(nonaktif|matikan|disable|reset|ubah)"),
    ("account_takeover", 22, "Meminta mengubah email/nomor pemulihan akun.",
     r"(ubah|ganti|change)\w*.{0,20}(email|nomor|number).{0,20}(pemulihan|recovery|akun)"),

    # ---- malware --------------------------------------------------------
    ("malware", 42, "Menyebut file yang bisa berisi malware (.apk/.exe).",
     r"\.(apk|xapk|apks|exe|scr|bat|cmd|msi|jar|vbs|ps1|iso|dmg|lnk)\b"),
    ("malware", 20, "Meminta memasang aplikasi/file dari pihak tak dikenal.",
     r"(install|instal|pasang|unduh|download|buka|jalankan)\w*.{0,30}(aplikasi|app\b|apk|file|berkas|lampiran|attachment)"),
    ("malware", 30, "Meminta mengizinkan instalasi dari sumber tidak dikenal.",
     r"(sumber\s+tidak\s+dikenal|unknown\s+sources?|izinkan\s+(instalasi|pemasangan)|allow\s+(install|unknown))"),
    ("malware", 38, "Meminta izin Aksesibilitas/admin perangkat (dipakai malware perbankan).",
     r"(aktifkan|izinkan|berikan|allow|enable|grant).{0,30}(aksesibilitas|accessibility|akses\s+penuh|admin\s+perangkat|device\s+admin|tampil\s+di\s+atas\s+aplikasi)"),
    ("malware", 25, "Lampiran bernama dokumen resmi tetapi berupa file aplikasi/arsip.",
     r"(undangan|surat\s+(tilang|panggilan)|e-?tilang|resi|tagihan|foto|bukti\s+transfer|lampiran)\w*.{0,15}\.(apk|exe|zip|rar|scr)"),

    # ---- prizes / giveaways / social aid --------------------------------
    ("prize_scam", 28, "Mengabarkan Anda 'menang/terpilih' tanpa ikut apa pun.",
     r"selamat.{0,50}(menang|terpilih|mendapatkan|beruntung|pemenang)"),
    ("prize_scam", 25, "Menjanjikan hadiah/undian.",
     r"(menang|memenangkan|raih|dapat|dapatkan|terpilih)\w*\s+(hadiah|undian|mobil|motor|uang|voucher|iphone|saldo)"),
    ("prize_scam", 20, "Menyebut undian berhadiah.",
     r"(undian\s+berhadiah|giveaway|lotre|lottery|sweepstake)"),
    ("prize_scam", 25, "Meminta klaim/penukaran hadiah.",
     r"(klaim|tukarkan|tukar|ambil|redeem|claim)\s+(hadiah|bonus|voucher|reward|prize|sekarang|poin)"),
    ("prize_scam", 25, "Bahasa 'you have won' khas penipuan hadiah.",
     r"(you('ve|\s+have)\s+won|congratulations|winner|you\s+(are|were)\s+selected)"),
    ("prize_scam", 20, "Poin/reward yang 'akan hangus' untuk memancing klik.",
     r"(poin|point|reward|saldo\s+cashback).{0,25}(hangus|kedaluwarsa|kadaluarsa|expire|ditukar)"),
    ("prize_scam", 25, "Menjanjikan barang/saldo gratis.",
     r"(gratis|free).{0,20}(iphone|saldo|pulsa|kuota|dana\b|ovo|gopay|voucher|bansos|robux|diamond|skin)"),
    ("prize_scam", 28, "Mencatut bansos/BLT/subsidi.",
     r"(bansos|bantuan\s+sosial|blt|subsidi|pkh|kartu\s+prakerja).{0,40}(cair|klaim|daftar|cek|link|tautan|verifikasi)"),
]
