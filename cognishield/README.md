# CogniShield

Aplikasi keamanan (Flutter) + backend analisis (FastAPI) yang mendeteksi **18 jenis ancaman** lewat tiga jalur:
**tempel/scan manual**, **teks yang disalin (Clipboard Guard)**, dan **notifikasi masuk (Notification Guard, Android)**.

```
cognishield/
├── backend/   FastAPI + engine (analyzer.py, urlcheck.py, rules_*.py)
└── app/       Flutter (lib/, android_native/, setup_android.ps1)
```

## Yang dideteksi

Phishing · Pencurian OTP & data pribadi · Pembajakan akun (WhatsApp "kode salah kirim", QR) · Malware/APK ·
Hadiah & bansos palsu · Investasi/kripto palsu · Judi online · Pinjol ilegal · Lowongan kerja palsu ·
Pencatutan polisi/bank/instansi · Paket/kurir palsu · "Ini nomor baru saya" · Pemerasan/ransomware ·
CS & layanan palsu (AnyDesk) · Penipuan jual-beli · Asmara/warisan · Hoaks/propaganda · Tautan berbahaya.

Tautan diperiksa dari pola domain: pemendek URL, IP, punycode, TLD berisiko, hosting gratis, unduhan `.apk/.exe`,
domain yang meniru/typo merek (`klikbca-…`, `tokopedla.com`), pengalihan, dan kata pancingan.

## 1. Backend (PowerShell)

```powershell
cd backend
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python test_analyzer.py          # 8 tes engine
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Dokumentasi API: http://127.0.0.1:8000/docs

## 2. Aplikasi Flutter

```powershell
cd app
flutter create . --project-name cognishield --platforms=web,android   # sekali saja
flutter pub get
flutter run -d chrome
```

Chrome mendukung scan manual. Untuk **Notification Guard** pakai Android (emulator atau HP):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup_android.ps1        # sekali saja: memasang modul native + AndroidManifest
flutter run                # pilih perangkat Android
```

Lalu di aplikasi: **Protection → Notification Guard** → nyalakan → *Grant notification access* → aktifkan CogniShield → kembali ke aplikasi.

| Perangkat        | Alamat backend                                      |
|------------------|-----------------------------------------------------|
| Chrome           | `http://127.0.0.1:8000` (otomatis)                  |
| Emulator Android | `http://10.0.2.2:8000` (otomatis)                   |
| HP fisik         | `http://IP-LAPTOP:8000` di Settings → Backend Server (satu Wi-Fi, izinkan port 8000 di Firewall) |

### Menguji notifikasi di emulator

```powershell
adb shell cmd notification post -S bigtext -t "Bank" T1 "Akun Anda dibekukan, segera verifikasi di bit.ly/update-akun"
```

Harus muncul notifikasi "Waspada: Phishing / Pencurian Akun" dari CogniShield.

## API

`POST /analyze/auto` (semua jenis) · `/analyze/url` · `/analyze/notification` · `/analyze/propaganda` ·
`GET /stats` · `GET /history` · `GET /categories` · `DELETE /history`.
Body: `{"text": "...", "source": "manual|clipboard|notification", "app": "WhatsApp"}`.

## Batasan yang jujur

- Engine **berbasis aturan & pola** (107 aturan), bukan model ML. Penipuan baru dengan gaya bahasa lain bisa lolos,
  dan pesan sah yang terdengar mirip penipuan bisa ditandai. Hasilnya skor risiko, bukan kepastian.
- Tautan **tidak dibuka** dan tidak dicek ke database reputasi (mis. Google Safe Browsing); usia domain tidak diketahui.
- Notification Guard hanya **Android**, perlu izin *Notification Access*, dan memerlukan backend yang bisa dijangkau.
  Notifikasi dari aplikasi yang diblokir/di-mute sistem mungkin tidak terbaca.
- Clipboard Guard memeriksa saat aplikasi dibuka kembali (Android membatasi pembacaan clipboard di latar belakang). Tidak jalan di web.
- Privasi: teks hanya dikirim ke **backend milikmu** dan hanya bila mengandung tautan atau kata khas penipuan.
  Hasil aman dari clipboard/notifikasi tidak dicatat di riwayat. Riwayat di memori server dan hilang saat server restart.
- iOS tidak mengizinkan aplikasi membaca notifikasi aplikasi lain.

## Memasang IndoBERT nanti

```python
import analyzer
def indobert_prob(text: str) -> float:   # kembalikan 0..1 (peluang hoaks/propaganda)
    ...
analyzer.register_text_model(indobert_prob)
```
