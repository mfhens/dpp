"""
Mock implementations of external services for development mode.
These stubs allow the API to run without Docker dependencies.
"""
from __future__ import annotations

from typing import Optional
import logging

logger = logging.getLogger(__name__)


class MockMinIOService:
    """
    Mock MinIO object storage for development.
    Simulates file uploads without actually storing data.
    """
    
    def __init__(self):
        self.objects = {}
        logger.info("MockMinIOService initialized (dev mode)")
    
    def put_object(self, bucket: str, key: str, body: bytes) -> str:
        """Simulate object upload, return mock URL."""
        mock_url = f"http://localhost:9000/{bucket}/{key}"
        self.objects[f"{bucket}/{key}"] = {
            "size": len(body),
            "url": mock_url
        }
        logger.debug(f"Mock upload: {bucket}/{key} ({len(body)} bytes)")
        return mock_url
    
    def get_object(self, bucket: str, key: str) -> Optional[bytes]:
        """Simulate object download."""
        obj = self.objects.get(f"{bucket}/{key}")
        if obj:
            logger.debug(f"Mock download: {bucket}/{key}")
            return b"mock-data"
        return None


class MockImmuDBService:
    """
    Mock ImmuDB audit log for development.
    Logs to stdout instead of immutable database.
    """
    
    def __init__(self):
        self.audit_log = []
        logger.info("MockImmuDBService initialized (dev mode)")
    
    def append(self, event_type: str, data: dict) -> bool:
        """Simulate audit log append."""
        entry = {
            "event_type": event_type,
            "data": data
        }
        self.audit_log.append(entry)
        logger.info(f"Mock audit: {event_type} - {data}")
        return True
    
    def query(self, filters: dict) -> list:
        """Simulate audit log query."""
        return [e for e in self.audit_log if all(
            e.get(k) == v for k, v in filters.items()
        )]


class MockOPAService:
    """
    Mock Open Policy Agent for development.
    Always allows requests (no policy enforcement).
    """
    
    def __init__(self):
        logger.info("MockOPAService initialized (dev mode - all requests allowed)")
    
    def evaluate(self, input_data: dict) -> dict:
        """Simulate policy evaluation - always allow."""
        logger.debug(f"Mock OPA evaluation: {input_data} -> ALLOW")
        return {
            "result": True,
            "allow": True
        }


class MockAuthService:
    """
    Mock authentication service for development.
    Generates fake tokens without validating.
    """
    
    def __init__(self):
        self.mock_user = {
            "sub": "dev-user-123",
            "email": "dev@localhost",
            "name": "Development User"
        }
        logger.info("MockAuthService initialized (dev mode - no auth required)")
    
    def verify_token(self, _token: Optional[str] = None) -> dict:
        """Return mock user without validation."""
        # _token parameter accepted for API compatibility but intentionally not used
        logger.debug("Mock auth: returning dev user")
        return self.mock_user
    
    def create_mock_token(self) -> str:
        """Generate a fake token for testing."""
        return "dev-mock-token-12345"


# Global instances for development mode
_mock_minio: Optional[MockMinIOService] = None
_mock_immudb: Optional[MockImmuDBService] = None
_mock_opa: Optional[MockOPAService] = None
_mock_auth: Optional[MockAuthService] = None


def get_mock_services(enable: bool = True):
    """
    Initialize and return mock service instances.
    Only creates instances if enable=True (development mode).
    """
    global _mock_minio, _mock_immudb, _mock_opa, _mock_auth
    
    if not enable:
        return None, None, None, None
    
    if _mock_minio is None:
        _mock_minio = MockMinIOService()
        _mock_immudb = MockImmuDBService()
        _mock_opa = MockOPAService()
        _mock_auth = MockAuthService()
        
        logger.info("🎭 Mock services initialized for development mode")
    
    return _mock_minio, _mock_immudb, _mock_opa, _mock_auth
