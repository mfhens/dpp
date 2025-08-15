# auth.py
from __future__ import annotations

import os
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import requests
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from jwt import PyJWKClient, InvalidTokenError

# ---------- Configuration via env ----------
OIDC_ISSUER_URL = os.getenv("OIDC_ISSUER_URL", "http://keycloak:8080/realms/dpp").rstrip("/")
OIDC_AUDIENCE = os.getenv("OIDC_AUDIENCE", "dpp-api")  # if empty, audience is not verified
OIDC_ALGS = [a.strip() for a in os.getenv("OIDC_ALGS", "RS256,PS256,ES256").split(",") if a.strip()]
ALLOW_ANON_PUBLIC = os.getenv("ALLOW_ANON_PUBLIC", "1").lower() in {"1", "true", "yes"}
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
        claims = jwt.decode(
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

    if not credentials or not credentials.scheme.lower().startswith("bearer"):
        if ALLOW_ANON_PUBLIC and method == "GET":
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
                raise HTTPException(status_code=403, detail="Forbidden by policy")
            return principal

        raise HTTPException(
            status_code=401,
            detail="Missing bearer token",
            headers={"WWW-Authenticate": 'Bearer realm="dpp", error="missing_token"'},
        )

    token = credentials.credentials

    # Verify JWT
    claims = _decode_and_verify(token, OIDC_ISSUER_URL, OIDC_AUDIENCE if OIDC_AUDIENCE else None)
    principal = Principal(
        sub=str(claims.get("sub", "")),
        realm=_get_realm_from_issuer(claims.get("iss", OIDC_ISSUER_URL)),
        scopes=_extract_scopes(claims),
        claims=claims,
    )

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
        raise HTTPException(status_code=403, detail="Forbidden by policy")

    return principal
