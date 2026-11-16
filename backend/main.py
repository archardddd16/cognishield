"""CogniShield API (FastAPI).

Run:  python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Docs: http://127.0.0.1:8000/docs
"""
from __future__ import annotations

import itertools
import threading
from collections import deque
from datetime import datetime, timezone
from typing import Callable, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import analyzer
import vt
from analyzer import Analysis

app = FastAPI(title="CogniShield API", version="2.2.0")

# VirusTotal aktif hanya jika VT_API_KEY diisi di lingkungan server (tidak pernah di kode).
VT_ENABLED = vt.install(analyzer)

# Needed so Flutter Web (Chrome) can call the API from another origin.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

_lock = threading.Lock()
_history: deque[dict] = deque(maxlen=300)  # in-memory; resets when the server restarts
_ids = itertools.count(1)


class ScanRequest(BaseModel):
    text: str = Field(..., max_length=5000, description="Teks, pesan, atau tautan yang diperiksa")
    source: str = Field("manual", description="manual | clipboard | notification")
    app: Optional[str] = Field(None, max_length=80, description="Nama aplikasi asal notifikasi")


def _serialize(a: Analysis) -> dict:
    worst = max(a.urls, key=lambda u: u.risk) if a.urls else None
    return {
        "kind": a.kind,
        "label": a.label,
        "warning_title": a.title,
        "level": a.level,
        "is_threat": a.level == "danger",
        "risk_score": a.risk,
        "primary": a.primary,
        "categories": a.categories,
        "reasons": a.reasons,
        "advice": a.advice,
        "engine": a.engine,
        "confidence": a.confidence,
        "agreement": a.agreement,
        "cognitive_score": a.cognitive_score,
        "tactics": [{k: t[k] for k in ("id", "name", "principle", "evidence")} for t in a.tactics],
        "layers": [{k: l[k] for k in ("id", "name", "active", "fired", "score", "detail")} for l in a.layers],
        "links": [
            {"url": u.url, "status": u.status, "level": u.level, "risk_score": u.risk, "reasons": u.reasons, "vt": u.vt}
            for u in a.urls[:6]
        ],
        "url_info": {
            "has_url": worst is not None,
            "detected_url": worst.url if worst else None,
            "url_status": worst.status if worst else None,
            "risk_score": worst.risk if worst else 0,
            "reasons": worst.reasons if worst else [],
            "all_urls": [u.url for u in a.urls],
        },
    }


def _run(req: ScanRequest, fn: Callable[[str], Analysis]) -> dict:
    text = req.text.strip()
    if not text:
        raise HTTPException(status_code=422, detail="Teks tidak boleh kosong.")
    result = _serialize(fn(text))
    # Automatic sources (clipboard / notifications) only log findings, never safe items.
    if req.source != "manual" and result["level"] == "safe":
        return result
    preview = f"[{req.app}] {text}" if req.app else text
    with _lock:
        _history.appendleft(
            {
                "id": next(_ids),
                "kind": result["kind"],
                "source": req.source,
                "preview": preview[:140],
                "label": result["label"],
                "title": result["warning_title"],
                "level": result["level"],
                "risk_score": result["risk_score"],
                "primary": result["primary"],
                "categories": result["categories"],
                "reasons": result["reasons"],
                "advice": result["advice"],
                "confidence": result["confidence"],
                "links": len(result["links"]),
                "time": datetime.now(timezone.utc).isoformat(),
            }
        )
    return result


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "CogniShield", "version": app.version, "virustotal": VT_ENABLED}


@app.post("/analyze/auto")
def analyze_auto(req: ScanRequest) -> dict:
    """Scan anything (message, notification, news, link) for every threat type."""
    return _run(req, analyzer.analyze_auto)


@app.post("/analyze/propaganda")
def analyze_propaganda(req: ScanRequest) -> dict:
    return _run(req, analyzer.analyze_propaganda)


@app.post("/analyze/url")
def analyze_url(req: ScanRequest) -> dict:
    return _run(req, analyzer.analyze_url_only)


@app.post("/analyze/notification")
def analyze_notification(req: ScanRequest) -> dict:
    return _run(req, analyzer.analyze_notification)


@app.get("/categories")
def categories() -> dict:
    return {"categories": [{"id": k, "name": v} for k, v in analyzer.CATEGORY_NAMES.items()]}


@app.get("/stats")
def stats() -> dict:
    with _lock:
        items = list(_history)
    recent = items[:20]
    score = 100
    if recent:
        avg = sum(i["risk_score"] for i in recent) / len(recent)
        score = max(0, round(100 - 0.6 * avg))
    danger_recent = any(i["level"] == "danger" for i in items[:5])
    status = "DANGER" if danger_recent and score < 60 else "ATTENTION" if danger_recent else "SECURE"
    return {
        "security_score": score,
        "status": status,
        "total_scans": len(items),
        "links_scanned": sum(i["links"] for i in items),
        "hoax_flagged": sum(1 for i in items if i.get("primary") == "hoax"),
        "notifications_scanned": sum(1 for i in items if i.get("source") == "notification"),
        "threats_blocked": sum(1 for i in items if i["level"] == "danger"),
        "recent": recent,
    }


@app.get("/history")
def history(limit: int = 100) -> dict:
    limit = max(1, min(limit, 300))
    with _lock:
        return {"items": list(_history)[:limit]}


@app.delete("/history")
def clear_history() -> dict:
    with _lock:
        _history.clear()
    return {"cleared": True}
