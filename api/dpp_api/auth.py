# auth.py
from __future__ import annotations

import os
import time
import logging
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import requests
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import decode as jwt_decode
from jwt import PyJWKClient
from jwt.exceptions import InvalidTokenError

# Setup logging
logger = logging.getLogger(__name__)

# ---------- Configuration via env ----------
OIDC_ISSUER_URL = os.getenv("OIDC_ISSUER_URL", "http://keycloak:8080/realms/dpp").rstrip("/")
OIDC_AUDIENCE = os.getenv("OIDC_AUDIENCE", "dpp-api")  # if empty, audience is not verified
OIDC_ALGS = [a.strip() for a in os.getenv("OIDC_ALGS", "RS256,PS256,ES256").split(",") if a.strip()]
ALLOW_ANON_PUBLIC = os.getenv("ALLOW_ANON_PUBLIC", "1").lower() in {"1", "true", "yes"}
DEMO_MODE = os.getenv("DEMO_MODE", "0").lower() in {"1", "true", "yes"}  # Allow anonymous POST for demos
OPA_URL = os.getenv("OPA_URL")  # example: http://opa:8181/v1/data/dpp/allow

HTTP_BEARER = HTTPBearer(auto_error=False)

# Cache JWK clients per issuer
_JWK_CLIENTS: Dict[str, PyJWKClient] = {}
_JWK_CLIENTS_TS: Dict[str, float] = {}
_JWK_TTL = float(os.getenv("JWK_CACHE_TTL_SECONDS", "300"))  # 5 min


@dataclass
class Principal:
    sub: str
    realm: str
    scopes: List[str]
    claims: Dict[str, Any]


def _get_realm_from_issuer(issuer: str) -> str:
    # Keycloak issuer ends with /realms/<realm>
    parts = issuer.rstrip("/").split("/")
    if "realms" in parts:
        i = parts.index("realms")
        if i + 1 < len(parts):
            return parts[i + 1]
    return "unknown"


def _get_jwk_client(issuer: str) -> PyJWKClient:
    now = time.time()
    client = _JWK_CLIENTS.get(issuer)
    ts = _JWK_CLIENTS_TS.get(issuer, 0)
    if client is None or (now - ts) > _JWK_TTL:
        jwks_uri = f"{issuer}/protocol/openid-connect/certs"
        client = PyJWKClient(jwks_uri)
        _JWK_CLIENTS[issuer] = client
        _JWK_CLIENTS_TS[issuer] = now
    return client


def _decode_and_verify(token: str, issuer: str, audience: Optional[str]) -> Dict[str, Any]:
    jwk_client = _get_jwk_client(issuer)
    signing_key = jwk_client.get_signing_key_from_jwt(token).key

    options = {"verify_aud": bool(audience)}
    try:
        claims = jwt_decode(
            token,
            signing_key,
            algorithms=OIDC_ALGS,
            audience=audience if audience else None,
            issuer=issuer,
            options=options,
        )
        return claims
    except InvalidTokenError as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid token: {str(e)}",
            headers={"WWW-Authenticate": 'Bearer realm="dpp", error="invalid_token"'},
        )


def _extract_scopes(claims: Dict[str, Any]) -> List[str]:
    scopes: List[str] = []
    # OIDC scope claim
    if "scope" in claims and isinstance(claims["scope"], str):
        scopes.extend([s for s in claims["scope"].split() if s])

    # Keycloak realm roles
    realm_access = claims.get("realm_access", {})
    if isinstance(realm_access, dict):
        roles = realm_access.get("roles", [])
        if isinstance(roles, list):
            scopes.extend([f"role:{r}" for r in roles])

    # Keycloak resource roles
    resource_access = claims.get("resource_access", {})
    if isinstance(resource_access, dict):
        for client, data in resource_access.items():
            rroles = data.get("roles", []) if isinstance(data, dict) else []
            for r in rroles:
                scopes.append(f"{client}:{r}")

    # Deduplicate while preserving order
    seen = set()
    uniq = []
    for s in scopes:
        if s not in seen:
            uniq.append(s)
            seen.add(s)
    return uniq


def _opa_allow(input_payload: Dict[str, Any]) -> bool:
    if not OPA_URL:
        return True
    try:
        resp = requests.post(OPA_URL, json={"input": input_payload}, timeout=2.0)
        resp.raise_for_status()
        data = resp.json()
        # OPA returns {"result": true|false}
        return bool(data.get("result", False))
    except Exception:
        # Fail open in the prototype
        return True


def _anonymous_principal() -> Principal:
    return Principal(sub="anonymous", realm="public", scopes=[], claims={"anon": True})


def oidc_oauth2(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTP_BEARER),
) -> Principal:
    """
    FastAPI dependency:
      - Verifies Bearer JWT against Keycloak JWKS
      - Optionally allows anonymous GET if ALLOW_ANON_PUBLIC=1
      - Optionally calls OPA to enforce ABAC
    Returns a Principal with sub, realm, scopes, and full claims.
    """
    method = request.method.upper()
    path_elems = [p for p in request.url.path.split("/") if p]
    access_tier = request.headers.get("x-access-tier", "public")
    
    logger.debug(f"🔐 Auth check: {method} {request.url.path}")

    if not credentials or not credentials.scheme.lower().startswith("bearer"):
        # Demo mode: Allow anonymous access for all methods
        if DEMO_MODE:
            logger.debug("   ⚠️  DEMO MODE: Anonymous access allowed")
            principal = _anonymous_principal()
            # OPA check for anonymous
            if not _opa_allow(
                {
                    "user": {"sub": principal.sub, "realm": principal.realm, "scopes": principal.scopes},
                    "method": method,
                    "path": path_elems,
                    "access_tier": access_tier,
                }
            ):
                logger.warning(f"   ❌ OPA denied anonymous access to {request.url.path}")
                raise HTTPException(status_code=403, detail="Forbidden by policy")
            logger.debug("   ✅ Anonymous access granted (DEMO MODE)")
            return principal
        
        # Production: Only allow anonymous GET
        if ALLOW_ANON_PUBLIC and method == "GET":
            logger.debug("   Anonymous access allowed for GET request")
            principal = _anonymous_principal()
            # OPA check for anonymous
            if not _opa_allow(
                {
                    "user": {"sub": principal.sub, "realm": principal.realm, "scopes": principal.scopes},
                    "method": method,
                    "path": path_elems,
                    "access_tier": access_tier,
                }
            ):
                logger.warning(f"   ❌ OPA denied anonymous access to {request.url.path}")
                raise HTTPException(status_code=403, detail="Forbidden by policy")
            logger.debug("   ✅ Anonymous access granted")
            return principal

        logger.warning(f"   ❌ Missing bearer token for {method} {request.url.path}")
        raise HTTPException(
            status_code=401,
            detail="Missing bearer token",
            headers={"WWW-Authenticate": 'Bearer realm="dpp", error="missing_token"'},
        )

    token = credentials.credentials
    logger.debug("   Verifying JWT token...")

    # Verify JWT
    try:
        claims = _decode_and_verify(token, OIDC_ISSUER_URL, OIDC_AUDIENCE if OIDC_AUDIENCE else None)
        principal = Principal(
            sub=str(claims.get("sub", "")),
            realm=_get_realm_from_issuer(claims.get("iss", OIDC_ISSUER_URL)),
            scopes=_extract_scopes(claims),
            claims=claims,
        )
        logger.debug(f"   ✅ Token verified for user: {principal.sub}")
        logger.debug(f"   Scopes: {', '.join(principal.scopes[:5])}{'...' if len(principal.scopes) > 5 else ''}")
    except HTTPException:
        logger.warning(f"   ❌ Token verification failed")
        raise

    # OPA enforcement
    if not _opa_allow(
        {
            "user": {"sub": principal.sub, "realm": principal.realm, "scopes": principal.scopes},
            "method": method,
            "path": path_elems,
            "access_tier": access_tier,
            # You can include more context such as tenant, dpp_id, etc.
        }
    ):
        logger.warning(f"   ❌ OPA denied access for {principal.sub} to {request.url.path}")
        raise HTTPException(status_code=403, detail="Forbidden by policy")
    
    logger.debug("   ✅ Authorization successful")
    return principal
