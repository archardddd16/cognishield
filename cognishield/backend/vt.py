"""Reputasi tautan lewat VirusTotal API v3 (opsional, stdlib only).

Aktif hanya jika variabel lingkungan VT_API_KEY diisi. Yang dikirim ke VirusTotal HANYA alamat
tautan (bukan isi pesan). Tidak pernah memblokir analisis: bila VirusTotal tidak bisa dijangkau,
kuota habis, atau hasil belum siap, lapisan ini dilewati dan mesin lokal tetap bekerja.

Akun gratis (public API): 4 permintaan/menit dan 500/hari, untuk penggunaan non-komersial.
Satu tautan yang BARU pertama kali dilihat butuh 3 permintaan (cek, kirim, ambil hasil), jadi
hasilnya bisa "pending" dan baru muncul saat tautan yang sama dipindai lagi.
"""
from __future__ import annotations

import base64
import json
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import deque
from typing import Callable, Optional

API = "https://www.virustotal.com/api/v3"
HttpFn = Callable[[str, str, dict, Optional[bytes]], tuple]  # (method, url, headers, body) -> (status, dict)


def url_id(url: str) -> str:
    return base64.urlsafe_b64encode(url.encode()).decode().rstrip("=")


def _normalize(url: str) -> str:
    url = url.strip()
    return url if url.lower().startswith(("http://", "https://")) else "http://" + url


def _urllib_http(method: str, url: str, headers: dict, body: Optional[bytes]) -> tuple:
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=6) as r:  # TLS verification stays on
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode() or "{}")
        except Exception:
            return e.code, {}
    except Exception:
        return 0, {}


class VirusTotal:
    def __init__(self, key: str, http: Optional[HttpFn] = None, now: Callable[[], float] = time.time,
                 sleep: Callable[[float], None] = time.sleep, wait_after_submit: float = 8.0,
                 per_minute: int = 4, per_day: int = 500) -> None:
        self.key = key
        self._http = http or _urllib_http
        self._now, self._sleep, self._wait = now, sleep, wait_after_submit
        self._per_minute, self._per_day = per_minute, per_day
        self._calls: deque[float] = deque()
        self._day_start, self._day_count = now(), 0
        self._cache: dict[str, tuple[float, dict]] = {}
        self._lock = threading.Lock()

    # -- quota ---------------------------------------------------------
    def _allow(self) -> bool:
        with self._lock:
            t = self._now()
            if t - self._day_start >= 86400:
                self._day_start, self._day_count = t, 0
            while self._calls and t - self._calls[0] >= 60:
                self._calls.popleft()
            if len(self._calls) >= self._per_minute or self._day_count >= self._per_day:
                return False
            self._calls.append(t)
            self._day_count += 1
            return True

    def _request(self, method: str, path: str, body: Optional[bytes] = None) -> tuple:
        headers = {"x-apikey": self.key, "accept": "application/json"}
        if body is not None:
            headers["content-type"] = "application/x-www-form-urlencoded"
        return self._http(method, API + path, headers, body)

    # -- result helpers --------------------------------------------------
    @staticmethod
    def _found(stats: dict, uid: str) -> dict:
        m, s = int(stats.get("malicious", 0)), int(stats.get("suspicious", 0))
        h, u = int(stats.get("harmless", 0)), int(stats.get("undetected", 0))
        return {"status": "found", "malicious": m, "suspicious": s, "harmless": h, "undetected": u,
                "total": m + s + h + u, "permalink": f"https://www.virustotal.com/gui/url/{uid}"}

    @staticmethod
    def _other(status: str, note: str) -> dict:
        return {"status": status, "note": note, "malicious": 0, "suspicious": 0, "harmless": 0,
                "undetected": 0, "total": 0, "permalink": None}

    def _cached(self, key: str) -> Optional[dict]:
        hit = self._cache.get(key)
        if hit and hit[0] > self._now():
            return hit[1]
        return None

    def _store(self, key: str, res: dict) -> dict:
        ttl = {"found": 6 * 3600, "pending": 20, "unavailable": 30}.get(res["status"], 30)
        if len(self._cache) > 500:
            self._cache.clear()
        self._cache[key] = (self._now() + ttl, res)
        return res

    # -- main ------------------------------------------------------------
    def check(self, url: str) -> dict:
        u = _normalize(url)
        uid = url_id(u)
        if (c := self._cached(uid)) is not None:
            return c
        if not self._allow():
            return self._other("unavailable", "Kuota gratis VirusTotal sedang habis.")
        status, body = self._request("GET", f"/urls/{uid}")
        if status == 200:
            stats = (((body.get("data") or {}).get("attributes") or {}).get("last_analysis_stats")) or {}
            if stats and sum(int(v) for v in stats.values()) > 0:
                return self._store(uid, self._found(stats, uid))
        elif status in (401, 403):
            return self._other("unavailable", "API key VirusTotal ditolak.")
        elif status == 429:
            return self._other("unavailable", "Kuota VirusTotal habis.")
        elif status not in (200, 404):
            return self._other("unavailable", "VirusTotal tidak dapat dijangkau.")

        # Tautan belum pernah dianalisis: kirim, tunggu sebentar, ambil hasil.
        if not self._allow():
            return self._other("unavailable", "Kuota gratis VirusTotal sedang habis.")
        status, body = self._request("POST", "/urls", urllib.parse.urlencode({"url": u}).encode())
        aid = ((body.get("data") or {}).get("id")) if status == 200 else None
        if not aid:
            return self._other("unavailable", "VirusTotal tidak menerima tautan ini.")
        self._sleep(self._wait)
        if not self._allow():
            return self._store(uid, self._other("pending", "VirusTotal sedang menganalisis tautan ini."))
        status, body = self._request("GET", f"/analyses/{aid}")
        attrs = (body.get("data") or {}).get("attributes") or {}
        if status == 200 and attrs.get("status") == "completed" and attrs.get("stats"):
            return self._store(uid, self._found(attrs["stats"], uid))
        return self._store(uid, self._other("pending", "VirusTotal sedang menganalisis tautan ini."))


def install(analyzer_module, key: Optional[str] = None, client: Optional[VirusTotal] = None) -> bool:
    """Pasang VirusTotal ke mesin bila ada API key. Mengembalikan True jika aktif."""
    key = key if key is not None else os.environ.get("VT_API_KEY", "").strip()
    if client is None:
        if not key:
            analyzer_module.register_url_reputation(None)
            return False
        client = VirusTotal(key)
    analyzer_module.register_url_reputation(client.check)
    return True