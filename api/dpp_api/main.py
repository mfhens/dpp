# main.py
from __future__ import annotations

import uuid
import datetime as dt
from typing import Optional
import os

from fastapi import FastAPI, Depends, HTTPException, Request, Header
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from pathlib import Path
import json
from jsonschema import Draft202012Validator

# Auth and service utilities (your existing modules)
from .auth import oidc_oauth2
from .services.identifiers import normalize_id, generate_dl
from .services.object_store import put_object
from .services.audit import audit_append

# DB models and helpers aligned with models.py
from .models import (
    init_db,
    get_session,
    Dpp,
    DppVersion,
    get_latest_dpp_version,
)

import hashlib
import base64

MAX_DB_ID_LEN = 512  # current DB schema

app = FastAPI(title="DPP API", version="0.2.0")

# Load canonical schema for payload validation
# Go up 2 levels: dpp_api/main.py -> dpp_api -> api -> project_root
SCHEMA_PATH = Path(__file__).resolve().parents[2] / "schemas" / "core" / "1-0-0.schema.json"
with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
    CORE_SCHEMA = json.load(f)
SCHEMA_VALIDATOR = Draft202012Validator(CORE_SCHEMA)


# -----------------------------
# Schemas
# -----------------------------
class DPPCreate(BaseModel):
    product_id: str
    model: str
    batch: Optional[str] = None
    payload: dict = Field(..., description="JSON-LD document")


class DPPVersionCreate(BaseModel):
    payload: dict = Field(..., description="JSON-LD document")
    valid_from: Optional[str] = Field(
        None,
        description="ISO-8601 timestamp; defaults to server UTC now if not provided",
    )


# -----------------------------
# Startup
# -----------------------------
@app.on_event("startup")
def startup() -> None:
    init_db()


# -----------------------------
# Helpers
# -----------------------------
def _utcnow() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def _parse_iso8601(value: str) -> dt.datetime:
    """
    Accepts RFC 3339/ISO 8601 such as:
      2025-08-14T10:20:30Z
      2025-08-14T10:20:30+00:00
      2025-08-14 10:20:30
    Returns timezone-aware UTC datetime.
    """
    v = value.strip()
    if v.endswith("Z"):
        v = v[:-1] + "+00:00"
    try:
        dt_obj = dt.datetime.fromisoformat(v)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid ISO-8601 timestamp")
    if dt_obj.tzinfo is None:
        dt_obj = dt_obj.replace(tzinfo=dt.timezone.utc)
    return dt_obj.astimezone(dt.timezone.utc)


def _validate_payload(payload: dict) -> None:
    """Validate DPP payload against canonical schema."""
    errors = sorted(SCHEMA_VALIDATOR.iter_errors(payload), key=lambda e: e.path)
    if errors:
        err = errors[0]
        loc = " -> ".join(str(x) for x in err.path)
        raise HTTPException(status_code=400, detail=f"Schema validation error at {loc}: {err.message}")


# -----------------------------
# Endpoints
# -----------------------------
@app.post("/dpp", response_model=dict)
def create_dpp(
    cmd: DPPCreate,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
):
    _validate_payload(cmd.payload)

    # 1) derive the canonical dpp_id from payload.id
    dpp_id = _extract_dpp_id(cmd.payload)

    # 2) figure out a sensible dpp_url
    # prefer payload.dppUrl; else build from API base (works for scanning)
    dpp_url = cmd.payload.get("dppUrl")
    if not dpp_url:
        base = os.env.get("PUBLIC_PORTAL_BASE", "http://localhost:3000")
        dpp_url = f"{base}/dpp/{dpp_id}"

    # 3) if header exists -> append new version
    header = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
    ts = _utcnow()

    if header:
        latest = get_latest_dpp_version(db, dpp_id)
        next_ver = (latest.version if latest else 0) + 1

        v = DppVersion(
            dpp_id=dpp_id,
            version=next_ver,
            valid_from=ts,
            payload=cmd.payload,
        )
        header.updated_at = ts
        db.add(v)
        db.commit()

        try:
            audit_append("dpp.version.create", {"dpp_id": dpp_id, "version": next_ver, "actor": getattr(token, "sub", None)})
        except Exception:
            pass

        return {"dpp_id": dpp_id, "dpp_url": header.dpp_url, "version": next_ver}

    # 4) else create header + v1
    # keep your request fields for product association for now
    pid = normalize_id(cmd.product_id)
    dl_uri = dpp_url  # align header URL with what we expose
    dpp = Dpp(dpp_id=dpp_id, product_id=pid, dpp_url=dl_uri)
    db.add(dpp)
    db.flush()

    v = DppVersion(dpp_id=dpp_id, version=1, valid_from=ts, payload=cmd.payload)
    dpp.updated_at = ts
    db.add(v)
    db.commit()

    try:
        audit_append("dpp.create", {"dpp_id": dpp_id, "actor": getattr(token, "sub", None)})
    except Exception:
        pass

    return {"dpp_id": dpp_id, "dpp_url": dl_uri, "version": 1}



@app.get("/dpp/{dpp_id}", response_model=dict)
def resolve_dpp(
    dpp_id: str,
    at: Optional[str] = None,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
):
    # Time-travel or latest read
    if at:
        t = _parse_iso8601(at)
        v = (
            db.query(DppVersion)
            .filter(DppVersion.dpp_id == dpp_id, DppVersion.valid_from <= t)
            .order_by(DppVersion.valid_from.desc())
            .first()
        )
    else:
        v = get_latest_dpp_version(db, dpp_id)

    # Audit every query call, including failures
    audit_data = {
        "dpp_id": dpp_id,
        "actor": getattr(token, "sub", None),
        "at": at,
        "success": bool(v),
        "version": v.version if v else None,
    }
    try:
        audit_append("dpp.query", audit_data)
    except Exception:
        pass

    if not v:
        raise HTTPException(status_code=404, detail="Not found")

    return {"dpp_id": dpp_id, "version": v.version, "payload": v.payload}


@app.post("/dpp/{dpp_id}/versions", response_model=dict)
def create_dpp_version(
    dpp_id: str,
    cmd: DPPVersionCreate,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
    expected_prev_version: Optional[int] = Header(
        default=None,
        alias="Expected-Prev-Version",
        description="If provided, ensures latest version matches this; else 409",
    ),
):
    # Ensure header exists
    dpp = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
    if not dpp:
        raise HTTPException(status_code=404, detail="DPP not found")

    # Determine current latest version under transaction
    latest = get_latest_dpp_version(db, dpp_id)

    prev = latest.version if latest else 0
    if expected_prev_version is not None and expected_prev_version != prev:
        raise HTTPException(
            status_code=409,
            detail=f"Version conflict: latest={prev}, expected={expected_prev_version}",
        )

    next_ver = prev + 1

    valid_from = _utcnow()
    if cmd.valid_from:
        valid_from = _parse_iso8601(cmd.valid_from)

    # Insert new version (append-only)
    _validate_payload(cmd.payload)
    v = DppVersion(
        dpp_id=dpp_id,
        version=next_ver,
        valid_from=valid_from,
        payload=cmd.payload,
    )
    dpp.updated_at = valid_from
    db.add(v)
    db.commit()

    # Audit
    try:
        audit_append(
            "dpp.version.create",
            {"dpp_id": dpp_id, "version": next_ver, "actor": getattr(token, "sub", None)},
        )
    except Exception:
        pass

    return {"dpp_id": dpp_id, "version": next_ver, "valid_from": valid_from.isoformat()}


@app.post("/dpp/{dpp_id}/attachments", response_model=dict)
async def upload_attachment(
    dpp_id: str,
    req: Request,
    token=Depends(oidc_oauth2),
):
    # Optional existence check
    # dpp = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first() ...

    filename = req.headers.get("x-filename", f"{uuid.uuid4()}.bin")
    body = await req.body()  # prototype: read into memory

    url = put_object(bucket="dpp", key=f"{dpp_id}/{filename}", body=body)

    try:
        audit_append(
            "dpp.attach",
            {"dpp_id": dpp_id, "key": filename, "actor": getattr(token, "sub", None)},
        )
    except Exception:
        pass

    return {"ok": True, "url": url}

def _extract_dpp_id(payload: dict) -> str:
    dpp_id = (payload or {}).get("id")
    if not dpp_id or not isinstance(dpp_id, str):
        raise HTTPException(status_code=400, detail="Payload.id is required and must be a string")

    # normalize if you have rules (DID/URL normalization, lowercase host, etc.)
    # here we reuse your existing normalize_id if it copes with URIs
    try:
        norm = normalize_id(dpp_id)
    except Exception:
        norm = dpp_id  # be permissive; schema already validated

    return norm
