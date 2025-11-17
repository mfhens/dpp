"""
Configuration management for DPP API.
Uses pydantic-settings to handle environment-based configuration.
"""
from __future__ import annotations

from typing import Literal, Optional
from pathlib import Path

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings with environment-based configuration.
    
    Environment Profiles:
    - development: SQLite, no auth, minimal services
    - docker: PostgreSQL, full stack in containers
    - production: PostgreSQL, all security features enabled
    """
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )
    
    # Environment profile
    environment: Literal["development", "docker", "production"] = Field(
        default="development",
        description="Runtime environment profile"
    )
    
    # Database configuration
    database_url: Optional[str] = Field(
        default=None,
        description="Database connection URL. If not set, uses SQLite in development."
    )
    database_url_file: Optional[Path] = Field(
        default=None,
        description="Path to file containing database URL (Docker secrets)"
    )
    sql_echo: bool = Field(
        default=False,
        description="Enable SQLAlchemy query logging"
    )
    
    # OIDC/Auth configuration
    oidc_issuer_url: str = Field(
        default="http://localhost:8080/realms/dpp",
        description="OIDC issuer URL (Keycloak)"
    )
    oidc_audience: str = Field(
        default="dpp-api",
        description="OIDC audience claim"
    )
    oidc_client_secret: Optional[str] = None
    oidc_client_secret_file: Optional[Path] = None
    
    # MinIO/Object Storage
    minio_endpoint: str = Field(
        default="http://localhost:9000",
        description="MinIO endpoint URL"
    )
    minio_access_key: Optional[str] = Field(default=None, alias="minio_root_user")
    minio_access_key_file: Optional[Path] = Field(default=None, alias="minio_root_user_file")
    minio_secret_key: Optional[str] = Field(default=None, alias="minio_root_password")
    minio_secret_key_file: Optional[Path] = Field(default=None, alias="minio_root_password_file")
    
    # ImmuDB (Audit Log)
    immudb_addr: str = Field(
        default="localhost:3322",
        description="ImmuDB connection address"
    )
    immudb_password: Optional[str] = None
    immudb_password_file: Optional[Path] = None
    
    # OPA (Policy)
    opa_url: str = Field(
        default="http://localhost:8181/v1/data/dpp/allow",
        description="Open Policy Agent decision endpoint"
    )
    
    # Security
    jwt_secret: Optional[str] = None
    jwt_secret_file: Optional[Path] = None
    encryption_key: Optional[str] = None
    encryption_key_file: Optional[Path] = None
    
    # Server
    api_host: str = Field(default="0.0.0.0")
    api_port: int = Field(default=8000)
    
    # Portal/Public URLs
    public_portal_base: str = Field(
        default="http://localhost:3000",
        description="Public-facing portal URL for DPP links"
    )
    
    @computed_field
    @property
    def resolved_database_url(self) -> str:
        """
        Resolve the database URL with priority:
        1. database_url_file (Docker secrets)
        2. database_url (direct env var)
        3. Environment-specific default
        """
        # Try file-based secret first
        if self.database_url_file and self.database_url_file.exists():
            return self.database_url_file.read_text().strip()
        
        # Try direct env var
        if self.database_url:
            return self.database_url
        
        # Environment-specific defaults
        if self.environment == "development":
            return "sqlite+pysqlite:///./dpp.db"
        else:  # docker or production
            raise ValueError(
                f"DATABASE_URL or DATABASE_URL_FILE must be set in {self.environment} environment"
            )
    
    @computed_field
    @property
    def enable_mock_services(self) -> bool:
        """
        In development mode, use mock/stub implementations for external services.
        """
        return self.environment == "development"
    
    @computed_field
    @property
    def require_authentication(self) -> bool:
        """
        Disable authentication in development for easier local testing.
        """
        return self.environment in ("docker", "production")
    
    def _read_secret_file(self, file_field: Optional[Path], env_field: Optional[str]) -> Optional[str]:
        """Helper to read from file or return env value."""
        if file_field and file_field.exists():
            return file_field.read_text().strip()
        return env_field
    
    def get_minio_credentials(self) -> tuple[Optional[str], Optional[str]]:
        """Resolve MinIO access key and secret key."""
        access_key = self._read_secret_file(self.minio_access_key_file, self.minio_access_key)
        secret_key = self._read_secret_file(self.minio_secret_key_file, self.minio_secret_key)
        return access_key, secret_key
    
    def get_immudb_password(self) -> Optional[str]:
        """Resolve ImmuDB password."""
        return self._read_secret_file(self.immudb_password_file, self.immudb_password)
    
    def get_jwt_secret(self) -> Optional[str]:
        """Resolve JWT secret."""
        return self._read_secret_file(self.jwt_secret_file, self.jwt_secret)
    
    def get_encryption_key(self) -> Optional[str]:
        """Resolve encryption key."""
        return self._read_secret_file(self.encryption_key_file, self.encryption_key)


# Global settings instance
settings = Settings()
