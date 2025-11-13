# main.py
from __future__ import annotations

import uuid
import datetime as dt
from typing import Optional
import os
import logging
from pathlib import Path
import threading

from fastapi import FastAPI, Depends, HTTPException, Request, Header, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
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

# Setup logging
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
log_to_file = os.environ.get("LOG_TO_FILE", "false").lower() == "true"
log_file = os.environ.get("LOG_FILE", "logs/dpp_api.log")

# Configure logging handlers
handlers = []

# Console handler
console_handler = logging.StreamHandler()
console_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
))
handlers.append(console_handler)

if log_to_file:
    # Create log directory if it doesn't exist
    log_path = Path(log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Add file handler with rotation
    from logging.handlers import RotatingFileHandler
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5,
        encoding='utf-8'
    )
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    ))
    handlers.append(file_handler)

# Get root logger and configure it
root_logger = logging.getLogger()
root_logger.setLevel(getattr(logging, log_level, logging.INFO))

# Remove existing handlers to avoid duplicates
for handler in root_logger.handlers[:]:
    root_logger.removeHandler(handler)

# Add our handlers
for handler in handlers:
    root_logger.addHandler(handler)

# Get our specific logger
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, log_level, logging.INFO))

# Log startup configuration
logger.info(f"🚀 DPP API starting with log level: {log_level}")
if log_to_file:
    logger.info(f"📝 Logging to file: {log_file}")

MAX_DB_ID_LEN = 512  # current DB schema

app = FastAPI(title="DPP API", version="0.2.0")

# Load canonical schema for payload validation
# Try multiple possible locations for the schema file
def find_schema_path() -> Path:
    """Find the schema file in various possible deployment locations."""
    schema_relative = "schemas/core/1-0-0.schema.json"
    
    # Possible base directories to search
    possible_bases = [
        Path(__file__).resolve().parents[2],  # Local dev: dpp_api/main.py -> dpp_api -> api -> project_root
        Path(__file__).resolve().parent.parent,  # Azure: /tmp/.../dpp_api/main.py -> /tmp/.../
        Path.cwd(),  # Current working directory
        Path("/home/site/wwwroot"),  # Azure App Service common path
    ]
    
    for base in possible_bases:
        schema_path = base / schema_relative
        if schema_path.exists():
            logger.info(f"📋 Found schema at: {schema_path}")
            return schema_path
    
    # If not found, log all attempted paths
    attempted = [str(base / schema_relative) for base in possible_bases]
    logger.error(f"❌ Schema file not found. Attempted paths: {attempted}")
    raise FileNotFoundError(f"Schema file not found. Attempted: {attempted}")

SCHEMA_PATH = find_schema_path()
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
# Health check endpoint
@app.get("/health")
@app.head("/health")
def health_check():
    """Health check endpoint for monitoring and load balancers."""
    return {"status": "healthy", "service": "dpp-api", "version": app.version}


@app.get("/")
def root():
    """Root endpoint with API information."""
    return {
        "service": "DPP API",
        "version": app.version,
        "docs": "/docs",
        "health": "/health"
    }


# -----------------------------
# Global observer for file watcher
_file_watcher_observer = None

@app.on_event("startup")
def startup() -> None:
    global _file_watcher_observer
    
    logger.info("🚀 DPP API startup initiated")
    
    # Initialize database
    logger.info("📊 Initializing database...")
    try:
        init_db()
        logger.info("✅ Database initialized successfully")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
        logger.exception("Full traceback:")
        raise
    
    # Start file watcher if enabled
    enable_watcher = os.environ.get("ENABLE_FILE_WATCHER", "true").lower() == "true"
    if enable_watcher:
        try:
            from .planning_insights_watcher import watch_folder
            
            # Determine drop folder location
            drop_folder = Path(__file__).resolve().parents[1] / "drop"
            drop_folder_env = os.environ.get("DROP_FOLDER")
            if drop_folder_env:
                drop_folder = Path(drop_folder_env)
            
            # Get debounce setting
            debounce_seconds = float(os.environ.get("WATCHER_DEBOUNCE", "2.0"))
            
            logger.info("�️  Starting Planning Insights File Watcher")
            logger.info(f"   Drop folder: {drop_folder}")
            logger.info(f"   Debounce: {debounce_seconds}s")
            
            # Start watcher in background mode (non-blocking)
            _file_watcher_observer = watch_folder(
                drop_folder=drop_folder,
                debounce_seconds=debounce_seconds,
                run_forever=False
            )
            
            logger.info("✅ File watcher started successfully")
        except Exception as e:
            logger.error(f"❌ Failed to start file watcher: {e}")
            logger.exception("Full traceback:")
    else:
        logger.info("ℹ️  File watcher disabled (set ENABLE_FILE_WATCHER=true to enable)")
    
    logger.info("✅ DPP API startup complete")


@app.on_event("shutdown")
def shutdown() -> None:
    global _file_watcher_observer
    
    logger.info("🛑 DPP API shutdown initiated")
    
    # Stop file watcher if running
    if _file_watcher_observer:
        logger.info("Stopping file watcher...")
        try:
            _file_watcher_observer.stop()
            _file_watcher_observer.join(timeout=5)
            logger.info("✅ File watcher stopped")
        except Exception as e:
            logger.error(f"Error stopping file watcher: {e}")
    
    logger.info("✅ DPP API shutdown complete")


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
    logger.debug("Validating payload against schema...")
    errors = sorted(SCHEMA_VALIDATOR.iter_errors(payload), key=lambda e: e.path)
    if errors:
        err = errors[0]
        loc = " -> ".join(str(x) for x in err.path)
        error_msg = f"Schema validation error at {loc}: {err.message}"
        logger.error(f"Schema validation failed: {error_msg}")
        raise HTTPException(status_code=400, detail=error_msg)
    logger.debug("✅ Schema validation passed")


# -----------------------------
# Endpoints
# -----------------------------
@app.get("/dpp", response_model=list)
def list_dpps(
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
    skip: int = 0,
    limit: int = 100,
    product_id: Optional[str] = None,
):
    """
    List all DPPs in the database.
    Returns basic header information for each DPP.
    
    Args:
        skip: Number of records to skip (pagination)
        limit: Maximum number of records to return
        product_id: Optional filter by product_id (case-insensitive search)
    """
    actor = getattr(token, "sub", "unknown")
    logger.info(f"📋 List DPPs request from actor: {actor}")
    logger.debug(f"   Skip: {skip}, Limit: {limit}")
    if product_id:
        logger.debug(f"   Filter by product_id: {product_id}")
    
    try:
        query = db.query(Dpp)
        
        # Apply case-insensitive product_id filter if provided
        if product_id:
            # Normalize the search term
            normalized_search = normalize_id(product_id)
            # Use case-insensitive LIKE search on normalized product_id
            query = query.filter(Dpp.product_id.ilike(f"%{normalized_search}%"))
        
        dpps = query.offset(skip).limit(limit).all()
        logger.info(f"   ✅ Found {len(dpps)} DPPs")
        
        result = [
            {
                "id": dpp.dpp_id,
                "product_id": dpp.product_id,
                "dpp_url": dpp.dpp_url,
                "created_at": dpp.created_at.isoformat() if dpp.created_at else None,
                "updated_at": dpp.updated_at.isoformat() if dpp.updated_at else None,
            }
            for dpp in dpps
        ]
        
        try:
            audit_append("dpp.list", {"actor": actor, "count": len(dpps), "product_id_filter": product_id})
        except Exception as e:
            logger.warning(f"   Audit log failed: {e}")
        
        return result
        
    except Exception as e:
        logger.error(f"   ❌ Failed to list DPPs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list DPPs: {str(e)}")


@app.get("/dpp/search", response_model=list)
def search_dpps(
    q: str,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
    limit: int = 50,
):
    """
    Search DPPs by product_id or model (case-insensitive).
    
    Args:
        q: Search query string (searches product_id and model fields)
        limit: Maximum number of results to return
    
    Returns:
        List of matching DPPs with their latest version payloads
    """
    actor = getattr(token, "sub", "unknown")
    logger.info(f"🔍 Search DPPs request from actor: {actor}")
    logger.debug(f"   Query: {q}, Limit: {limit}")
    
    try:
        # Normalize search query
        normalized_query = normalize_id(q)
        logger.debug(f"   Normalized query: {normalized_query}")
        
        # Search by product_id (case-insensitive)
        dpps_by_product = (
            db.query(Dpp)
            .filter(Dpp.product_id.ilike(f"%{normalized_query}%"))
            .limit(limit)
            .all()
        )
        
        results = []
        seen_ids = set()
        
        # Add results from product_id search
        for dpp in dpps_by_product:
            if dpp.dpp_id not in seen_ids:
                seen_ids.add(dpp.dpp_id)
                latest = get_latest_dpp_version(db, dpp.dpp_id)
                results.append({
                    "id": dpp.dpp_id,
                    "product_id": dpp.product_id,
                    "dpp_url": dpp.dpp_url,
                    "version": latest.version if latest else None,
                    "match_field": "product_id",
                })
        
        # Also search by model in payload (if we haven't hit limit)
        if len(results) < limit:
            remaining_limit = limit - len(results)
            versions = (
                db.query(DppVersion)
                .order_by(DppVersion.dpp_id, DppVersion.version.desc())
                .distinct(DppVersion.dpp_id)
                .limit(remaining_limit * 2)  # Get more to filter
                .all()
            )
            
            for v in versions:
                if v.dpp_id in seen_ids:
                    continue
                    
                payload = v.payload or {}
                product = payload.get("product", {})
                model = product.get("model", "")
                
                # Case-insensitive model match
                if model and normalized_query in model.lower():
                    seen_ids.add(v.dpp_id)
                    dpp = db.query(Dpp).filter(Dpp.dpp_id == v.dpp_id).first()
                    if dpp:
                        results.append({
                            "id": dpp.dpp_id,
                            "product_id": dpp.product_id,
                            "dpp_url": dpp.dpp_url,
                            "version": v.version,
                            "match_field": "model",
                            "model": model,
                        })
                        
                        if len(results) >= limit:
                            break
        
        logger.info(f"   ✅ Found {len(results)} matching DPPs")
        
        try:
            audit_append("dpp.search", {"actor": actor, "query": q, "count": len(results)})
        except Exception as e:
            logger.warning(f"   Audit log failed: {e}")
        
        return results
        
    except Exception as e:
        logger.error(f"   ❌ Search failed: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")


@app.post("/dpp", response_model=dict)
def create_dpp(
    cmd: DPPCreate,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
):
    actor = getattr(token, "sub", "unknown")
    logger.info(f"📝 Create DPP request from actor: {actor}")
    logger.debug(f"   Product ID: {cmd.product_id}, Model: {cmd.model}")
    
    try:
        _validate_payload(cmd.payload)
        logger.debug("   ✅ Payload validation passed")
    except HTTPException as e:
        logger.warning(f"   ❌ Payload validation failed: {e.detail}")
        raise

    # 1) derive the canonical dpp_id from payload.id
    dpp_id = _extract_dpp_id(cmd.payload)
    logger.debug(f"   DPP ID: {dpp_id}")

    # 2) figure out a sensible dpp_url
    # prefer payload.dppUrl; else build from API base (works for scanning)
    dpp_url = cmd.payload.get("dppUrl")
    if not dpp_url:
        base = os.env.get("PUBLIC_PORTAL_BASE", "http://localhost:3000")
        dpp_url = f"{base}/dpp/{dpp_id}"
    logger.debug(f"   DPP URL: {dpp_url}")

    # 3) if header exists -> append new version
    header = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
    ts = _utcnow()

    if header:
        logger.info(f"   DPP exists, creating new version")
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
        
        logger.info(f"   ✅ Created version {next_ver} for DPP: {dpp_id}")

        try:
            audit_append("dpp.version.create", {"dpp_id": dpp_id, "version": next_ver, "actor": actor})
        except Exception as e:
            logger.warning(f"   Audit log failed: {e}")

        return {"dpp_id": dpp_id, "dpp_url": header.dpp_url, "version": next_ver}

    # 4) else create header + v1
    logger.info(f"   Creating new DPP")
    pid = normalize_id(cmd.product_id)
    dl_uri = dpp_url  # align header URL with what we expose
    dpp = Dpp(dpp_id=dpp_id, product_id=pid, dpp_url=dl_uri)
    db.add(dpp)
    db.flush()

    v = DppVersion(dpp_id=dpp_id, version=1, valid_from=ts, payload=cmd.payload)
    dpp.updated_at = ts
    db.add(v)
    db.commit()
    
    logger.info(f"   ✅ Created new DPP: {dpp_id}")

    try:
        audit_append("dpp.create", {"dpp_id": dpp_id, "actor": actor})
    except Exception as e:
        logger.warning(f"   Audit log failed: {e}")

    return {"dpp_id": dpp_id, "dpp_url": dl_uri, "version": 1}



@app.get("/dpp/{dpp_id}", response_model=dict)
def resolve_dpp(
    dpp_id: str,
    at: Optional[str] = None,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
):
    actor = getattr(token, "sub", "unknown")
    logger.info(f"🔍 Resolve DPP request: {dpp_id}")
    logger.debug(f"   Actor: {actor}")
    if at:
        logger.debug(f"   Time-travel query at: {at}")
    
    # Time-travel or latest read
    if at:
        try:
            t = _parse_iso8601(at)
            v = (
                db.query(DppVersion)
                .filter(DppVersion.dpp_id == dpp_id, DppVersion.valid_from <= t)
                .order_by(DppVersion.valid_from.desc())
                .first()
            )
        except HTTPException as e:
            logger.warning(f"   ❌ Invalid timestamp: {at}")
            raise
    else:
        v = get_latest_dpp_version(db, dpp_id)

    # Audit every query call, including failures
    audit_data = {
        "dpp_id": dpp_id,
        "actor": actor,
        "at": at,
        "success": bool(v),
        "version": v.version if v else None,
    }
    try:
        audit_append("dpp.query", audit_data)
    except Exception as e:
        logger.warning(f"   Audit log failed: {e}")

    if not v:
        logger.warning(f"   ❌ DPP not found: {dpp_id}")
        raise HTTPException(status_code=404, detail="Not found")
    
    logger.info(f"   ✅ Found DPP version {v.version}")
    return {"dpp_id": dpp_id, "version": v.version, "payload": v.payload}


@app.delete("/dpp/{dpp_id}", response_model=dict)
def delete_dpp(
    dpp_id: str,
    token=Depends(oidc_oauth2),
    db: Session = Depends(get_session),
):
    """
    Delete a DPP and all its versions from the database.
    This is a destructive operation and cannot be undone.
    """
    actor = getattr(token, "sub", "unknown")
    logger.info(f"🗑️  Delete DPP request: {dpp_id}")
    logger.debug(f"   Actor: {actor}")
    
    try:
        # Check if DPP exists
        dpp = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
        if not dpp:
            logger.warning(f"   ❌ DPP not found: {dpp_id}")
            raise HTTPException(status_code=404, detail="DPP not found")
        
        # Delete all versions first (due to foreign key constraint)
        versions_deleted = db.query(DppVersion).filter(DppVersion.dpp_id == dpp_id).delete()
        logger.debug(f"   Deleted {versions_deleted} versions")
        
        # Delete the header
        db.delete(dpp)
        db.commit()
        
        logger.info(f"   ✅ Deleted DPP: {dpp_id}")
        
        # Audit the deletion
        try:
            audit_append(
                "dpp.delete",
                {
                    "dpp_id": dpp_id,
                    "actor": actor,
                    "versions_deleted": versions_deleted,
                }
            )
        except Exception as e:
            logger.warning(f"   Audit log failed: {e}")
        
        return {
            "ok": True,
            "dpp_id": dpp_id,
            "versions_deleted": versions_deleted,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"   ❌ Failed to delete DPP: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete DPP: {str(e)}")


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
    actor = getattr(token, "sub", "unknown")
    logger.info(f"📝 Create version for DPP: {dpp_id}")
    logger.debug(f"   Actor: {actor}")
    if expected_prev_version is not None:
        logger.debug(f"   Expected previous version: {expected_prev_version}")
    
    # Ensure header exists
    dpp = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
    if not dpp:
        logger.warning(f"   ❌ DPP not found: {dpp_id}")
        raise HTTPException(status_code=404, detail="DPP not found")

    # Determine current latest version under transaction
    latest = get_latest_dpp_version(db, dpp_id)

    prev = latest.version if latest else 0
    if expected_prev_version is not None and expected_prev_version != prev:
        logger.warning(f"   ❌ Version conflict: latest={prev}, expected={expected_prev_version}")
        raise HTTPException(
            status_code=409,
            detail=f"Version conflict: latest={prev}, expected={expected_prev_version}",
        )

    next_ver = prev + 1

    valid_from = _utcnow()
    if cmd.valid_from:
        valid_from = _parse_iso8601(cmd.valid_from)
        logger.debug(f"   Using custom valid_from: {valid_from}")

    # Insert new version (append-only)
    try:
        _validate_payload(cmd.payload)
        logger.debug("   ✅ Payload validation passed")
    except HTTPException as e:
        logger.warning(f"   ❌ Payload validation failed: {e.detail}")
        raise
        
    v = DppVersion(
        dpp_id=dpp_id,
        version=next_ver,
        valid_from=valid_from,
        payload=cmd.payload,
    )
    dpp.updated_at = valid_from
    db.add(v)
    db.commit()
    
    logger.info(f"   ✅ Created version {next_ver} for DPP: {dpp_id}")

    # Audit
    try:
        audit_append(
            "dpp.version.create",
            {"dpp_id": dpp_id, "version": next_ver, "actor": actor},
        )
    except Exception as e:
        logger.warning(f"   Audit log failed: {e}")

    return {"dpp_id": dpp_id, "version": next_ver, "valid_from": valid_from.isoformat()}


@app.post("/dpp/{dpp_id}/attachments", response_model=dict)
async def upload_attachment(
    dpp_id: str,
    req: Request,
    token=Depends(oidc_oauth2),
):
    actor = getattr(token, "sub", "unknown")
    filename = req.headers.get("x-filename", f"{uuid.uuid4()}.bin")
    
    logger.info(f"📎 Upload attachment to DPP: {dpp_id}")
    logger.debug(f"   Actor: {actor}")
    logger.debug(f"   Filename: {filename}")
    
    # Optional existence check
    # dpp = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first() ...

    body = await req.body()  # prototype: read into memory
    logger.debug(f"   Size: {len(body)} bytes")
    
    try:
        url = put_object(bucket="dpp", key=f"{dpp_id}/{filename}", body=body)
        logger.info(f"   ✅ Attachment uploaded: {filename}")
        logger.debug(f"   URL: {url}")
    except Exception as e:
        logger.error(f"   ❌ Upload failed: {e}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

    try:
        audit_append(
            "dpp.attach",
            {"dpp_id": dpp_id, "key": filename, "actor": actor},
        )
    except Exception as e:
        logger.warning(f"   Audit log failed: {e}")

    return {"ok": True, "url": url}

def _extract_dpp_id(payload: dict) -> str:
    """Extract and normalize DPP ID from payload."""
    dpp_id = (payload or {}).get("id")
    if not dpp_id or not isinstance(dpp_id, str):
        logger.error("Payload missing required 'id' field")
        raise HTTPException(status_code=400, detail="Payload.id is required and must be a string")

    # normalize if you have rules (DID/URL normalization, lowercase host, etc.)
    # here we reuse your existing normalize_id if it copes with URIs
    try:
        norm = normalize_id(dpp_id)
        logger.debug(f"Normalized DPP ID: {dpp_id} -> {norm}")
    except Exception as e:
        logger.warning(f"Could not normalize DPP ID '{dpp_id}': {e}")
        norm = dpp_id  # be permissive; schema already validated

    return norm


# -----------------------------
# File Upload API Endpoint
# -----------------------------
@app.post("/upload/planning-insights", response_model=dict)
async def upload_planning_insights_csv(
    file: UploadFile,
    token=Depends(oidc_oauth2),
):
    """
    Upload and process planning insights CSV file.
    For Azure App Service deployment - replaces file watcher.
    
    Note: Uses standard authentication. Works in DEMO_MODE for anonymous access.
    """
    actor = getattr(token, "sub", "unknown")
    logger.info(f"📤 CSV upload from actor: {actor}")
    logger.info(f"   Filename: {file.filename}")
    
    if not file.filename.endswith('.csv'):
        logger.warning(f"   ❌ Invalid file type: {file.filename}")
        raise HTTPException(
            status_code=400,
            detail="File must be .csv format"
        )
    
    try:
        # Read file content
        content = await file.read()
        logger.info(f"   File size: {len(content)} bytes")
        
        # Save to temp location and process using existing logic
        import tempfile
        with tempfile.NamedTemporaryFile(mode='wb', suffix='.csv', delete=False) as tmp:
            tmp.write(content)
            tmp_path = Path(tmp.name)
        
        try:
            from .planning_insights_watcher import process_csv_file
            result = process_csv_file(tmp_path)
            
            # Clean up temp file
            tmp_path.unlink()
            
            if not result.success and result.errors:
                error_msg = "; ".join(result.errors[:3])  # First 3 errors
                raise HTTPException(
                    status_code=500,
                    detail=f"Processing failed: {error_msg}"
                )
            
            logger.info(f"   ✅ Processed {result.dpps_updated} DPPs")
            
            # Audit the upload
            try:
                audit_append(
                    "planning_insights.upload",
                    {
                        "filename": file.filename,
                        "actor": actor,
                        "dpps_updated": result.dpps_updated,
                        "dpps_not_found": result.dpps_not_found
                    }
                )
            except Exception as e:
                logger.warning(f"   Audit log failed: {e}")
            
            return {
                "ok": True,
                "filename": file.filename,
                "dpps_updated": result.dpps_updated,
                "dpps_not_found": result.dpps_not_found,
                "records_read": result.records_read
            }
            
        except Exception as e:
            # Clean up temp file on error
            if tmp_path.exists():
                tmp_path.unlink()
            raise
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"   ❌ Processing error: {e}")
        logger.exception("Full traceback:")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process file: {str(e)}"
        )
