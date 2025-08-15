# audit.py
from __future__ import annotations

import json
import os
import hashlib
import time
from pathlib import Path
from typing import Any, Dict, Optional

# Optional immudb support; if not installed or not reachable, we fall back to a local hash-chained log file.
_IMMU_ADDR = os.getenv("IMMUDb_ADDR")  # e.g. "immudb:3322"
_IMMU_USER = os.getenv("IMMUDb_USER", "immudb")
_IMMU_PASS = os.getenv("IMMUDb_PASSWORD", "immudb")
_LOCAL_AUDIT_FILE = Path(os.getenv("LOCAL_AUDIT_FILE", "data/audit.log"))

try:
    # py-immudb client (optional). If missing, we transparently use file fallback.
    from immudb.client import ImmudbClient  # type: ignore
    _IMMUD_AVAILABLE = True
except Exception:
    _IMMUD_AVAILABLE = False


def _audit_local_append(event: str, payload: Dict[str, Any]) -> None:
    _LOCAL_AUDIT_FILE.parent.mkdir(parents=True, exist_ok=True)
    prev = ""
    if _LOCAL_AUDIT_FILE.exists():
        try:
            *_, last = _LOCAL_AUDIT_FILE.read_text(encoding="utf-8").splitlines()
            prev = json.loads(last).get("_hash", "")
        except Exception:
            prev = ""

    entry = {
        "ts": int(time.time() * 1000),
        "event": event,
        "payload": payload,
        "prev": prev,
    }
    h = hashlib.sha256(json.dumps(entry, sort_keys=True).encode("utf-8")).hexdigest()
    entry["_hash"] = h

    with _LOCAL_AUDIT_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, sort_keys=True) + "\n")


def _audit_immudb_append(event: str, payload: Dict[str, Any]) -> None:
    if not _IMMUD_AVAILABLE or not _IMMU_ADDR:
        raise RuntimeError("immudb client not available or IMMUDb_ADDR not set")

    host, port = _IMMU_ADDR.split(":")[0], int(_IMMU_ADDR.split(":")[1])
    c = ImmudbClient(host=host, port=port)
    c.login(_IMMU_USER, _IMMU_PASS)  # default creds for local dev
    # store as key-value with time-based keys; immudb keeps verifiable history
    key = f"dpp:audit:{int(time.time() * 1e6)}:{event}".encode("utf-8")
    val = json.dumps({"event": event, "payload": payload, "ts": int(time.time() * 1000)}).encode("utf-8")
    c.set(key, val)
    c.logout()


def audit_append(event: str, payload: Dict[str, Any]) -> None:
    """
    Append an audit event. Tries immudb first when configured, falls back to a local
    hash-chained append-only log file to preserve verifiability in the prototype.
    """
    try:
        if _IMMUD_AVAILABLE and _IMMU_ADDR:
            _audit_immudb_append(event, payload)
            return
    except Exception:
        # fall through to local file on any immudb errors
        pass

    _audit_local_append(event, payload)
