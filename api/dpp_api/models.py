# models.py
# SQLAlchemy 2.x models for a minimal DPP system: Dpp (header) + DppVersion (append-only versions)
# Works best with PostgreSQL and can fall back to SQLite for local ad-hoc runs.

from __future__ import annotations

import time
import datetime as dt
from typing import Iterator, List, Optional

from sqlalchemy import (
    create_engine,
    String,
    DateTime,
    Integer,
    ForeignKey,
    text,
    UniqueConstraint,
    Index,
    event,
)
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    mapped_column,
    relationship,
    sessionmaker,
    Session,
)
from sqlalchemy.exc import OperationalError

# Import config for environment-aware setup
from .config import settings

# Prefer PostgreSQL JSONB when available; otherwise use generic JSON (SQLite fallback)
try:
    from sqlalchemy.dialects.postgresql import JSONB as JSONType  # type: ignore
except Exception:  # pragma: no cover
    from sqlalchemy import JSON as JSONType  # type: ignore


# --------------------------------------------------------------------------------------
# Engine & Session
# --------------------------------------------------------------------------------------

ENGINE = create_engine(
    settings.resolved_database_url,
    echo=settings.sql_echo,
    pool_pre_ping=True,
    future=True
)
SessionLocal = sessionmaker(bind=ENGINE, autoflush=False, autocommit=False, expire_on_commit=False, class_=Session)


def get_session() -> Iterator[Session]:
    """
    FastAPI-compatible dependency:
        from fastapi import Depends
        def handler(db: Session = Depends(get_session)): ...
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db(create_views: bool = True) -> None:
    """
    Create tables and optional helper view. Safe to call multiple times.
    Includes a short readiness loop so startup doesn't race the DB container.
    """
    # Light readiness probe (useful when Compose says "started" but not yet accepting)
    for i in range(10):
        try:
            with ENGINE.connect() as conn:
                conn.exec_driver_sql("SELECT 1")
            break
        except OperationalError:
            time.sleep(0.5 + 0.5 * i)

    Base.metadata.create_all(ENGINE)
    if create_views:
        _ensure_views()


# --------------------------------------------------------------------------------------
# ORM Base
# --------------------------------------------------------------------------------------

class Base(DeclarativeBase):
    pass


# --------------------------------------------------------------------------------------
# Models
# --------------------------------------------------------------------------------------

class Dpp(Base):
    """
    DPP header: stable identity for a product/batch/item and its Digital Link.
    Versioned data lives in DppVersion (append-only).
    """
    __tablename__ = "dpp"

    dpp_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    product_id: Mapped[str] = mapped_column(String(255), index=True)
    dpp_url: Mapped[str] = mapped_column(String(1024), unique=True, index=True)
    created_at: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("NOW()"), index=True
    )
    updated_at: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("NOW()"),
        onupdate=text("NOW()"),
        index=True,
    )

    # versions relationship; delete-orphan to keep referential integrity clean
    versions: Mapped[List["DppVersion"]] = relationship(
        back_populates="dpp",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="desc(DppVersion.version)",
    )

    __table_args__ = (
        Index("ix_dpp_product_id_created", "product_id", "created_at"),
    )


class DppVersion(Base):
    """
    Append-only version row for a DPP. Each insert creates a new version number.
    Use application logic to increment `version`. We enforce uniqueness and sanity.
    """
    __tablename__ = "dpp_version"

    dpp_id: Mapped[str] = mapped_column(
        ForeignKey("dpp.dpp_id", ondelete="CASCADE"),
        primary_key=True,
    )
    version: Mapped[int] = mapped_column(Integer, primary_key=True)
    # Effective-from timestamp of this version
    valid_from: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("NOW()"),
        index=True,
    )
    # JSON-LD payload
    payload: Mapped[dict] = mapped_column(JSONType, nullable=False)

    dpp: Mapped[Dpp] = relationship(back_populates="versions")

    __table_args__ = (
        UniqueConstraint("dpp_id", "version", name="uq_dpp_version_id_ver"),
    )


# --------------------------------------------------------------------------------------
# Views & helpers
# --------------------------------------------------------------------------------------

LATEST_VIEW_SQL = """
CREATE OR REPLACE VIEW dpp_latest AS
SELECT DISTINCT ON (v.dpp_id)
    v.dpp_id,
    v.version,
    v.valid_from,
    v.payload
FROM dpp_version v
ORDER BY v.dpp_id, v.version DESC;
"""

def _ensure_views() -> None:
    """
    Create helper view for "latest version per DPP".
    Skips on non-Postgres engines.
    """
    if not ENGINE.dialect.name.startswith("postgres"):
        return
    with ENGINE.begin() as conn:
        conn.exec_driver_sql(LATEST_VIEW_SQL)


# --------------------------------------------------------------------------------------
# Convenience query functions
# --------------------------------------------------------------------------------------

def get_latest_dpp_version(db: Session, dpp_id: str) -> Optional[DppVersion]:
    return (
        db.query(DppVersion)
        .filter(DppVersion.dpp_id == dpp_id)
        .order_by(DppVersion.version.desc())
        .first()
    )


def get_dpp_as_of(db: Session, dpp_id: str, at: dt.datetime) -> Optional[DppVersion]:
    return (
        db.query(DppVersion)
        .filter(DppVersion.dpp_id == dpp_id, DppVersion.valid_from <= at)
        .order_by(DppVersion.valid_from.desc())
        .first()
    )


# --------------------------------------------------------------------------------------
# Safety rails: auto-sanitize version values
# --------------------------------------------------------------------------------------

@event.listens_for(DppVersion, "before_insert")
def _check_version_before_insert(mapper, connection, target: DppVersion) -> None:
    # Ensure version starts at 1
    if target.version is None or target.version < 1:
        target.version = 1


# --------------------------------------------------------------------------------------
# Smoke test
# --------------------------------------------------------------------------------------

if __name__ == "__main__":
    # Minimal sanity check: create schema and insert one DPP with a version.
    init_db()

    import uuid
    new_id = str(uuid.uuid4())

    with SessionLocal() as s:
        # Upsert header
        d = Dpp(
            dpp_id=new_id,
            product_id="urn:example:product:12345",
            dpp_url=f"https://example.org/dpp/{new_id}",
        )
        s.add(d)
        s.flush()

        v1 = DppVersion(
            dpp_id=d.dpp_id,
            version=1,
            payload={
                "@context": "https://example.org/contexts/dpp.jsonld",
                "@id": d.dpp_url,
                "modelNumber": "SANDVIK-X100",
                "batch": "B-2025-08-14",
                "manufacturer": {"name": "Sandvik", "lei": "5493001KJTIIGC8Y1R12"},
            },
        )
        s.add(v1)
        s.commit()

        got = get_latest_dpp_version(s, d.dpp_id)
        print("Inserted DPP:", d.dpp_id)
        print("Latest version:", got.version if got else None)
