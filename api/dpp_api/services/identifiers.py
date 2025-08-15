# identifiers.py
from __future__ import annotations

import os
import re
from urllib.parse import urlencode, quote


_DIGITAL_LINK_BASE = os.getenv("DIGITAL_LINK_BASE", "https://example.org/il")


def normalize_id(raw: str) -> str:
    """
    Normalize incoming product identifiers:
      - trim spaces
      - collapse internal whitespace
      - lowercase if it's not a pure numeric GTIN-like string
    This is intentionally conservative for a prototype.
    """
    if raw is None:
        raise ValueError("product_id is required")
    s = " ".join(raw.strip().split())

    # If this looks like a GTIN/EAN-like numeric string, keep case as-is and remove spaces
    if re.fullmatch(r"[0-9]{8,14}", s.replace(" ", "")):
        return s.replace(" ", "")

    return s.lower()


def generate_dl(product_id: str, model: str, batch: str | None = None) -> str:
    """
    Generate a simple GS1 Digital Link style URL for demo purposes.
    In a real system you would emit proper /ai/ paths (01=gtin, 10=batch, 21=serial).
    Here we keep it query-based to stay generic across ID types.

    Example:
      https://example.org/il?pid=01234567&model=MX-1&batch=B-2025-08
    """
    base = _DIGITAL_LINK_BASE.rstrip("/")
    q = {"pid": product_id, "model": model}
    if batch:
        q["batch"] = batch

    return f"{base}?{urlencode(q, doseq=False, safe=':/')}"
