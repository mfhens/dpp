"""
Seed database with Lego Duck sample data.
Works with both SQLite (development) and PostgreSQL (docker).
"""
from __future__ import annotations

import json
from pathlib import Path

from sqlalchemy.orm import Session

from .models import Dpp, DppVersion, SessionLocal, init_db
from .config import settings


def load_ndjson(file_path: Path) -> list[dict]:
    """Load NDJSON file (newline-delimited JSON)."""
    records = []
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    return records


def seed_from_ndjson(
    db: Session,
    ndjson_path: Path,
    skip_existing: bool = True
) -> tuple[int, int]:
    """
    Seed database from NDJSON file.
    
    Returns:
        Tuple of (created_count, skipped_count)
    """
    records = load_ndjson(ndjson_path)
    created = 0
    skipped = 0
    
    for doc in records:
        dpp_id = doc.get("id")
        if not dpp_id:
            print("⚠️  Skipping record without 'id' field")
            skipped += 1
            continue
        
        # Check if already exists
        existing = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
        if existing and skip_existing:
            skipped += 1
            continue
        
        if existing:
            # Update existing
            existing.updated_at = db.execute("SELECT NOW()").scalar()
            db.add(existing)
        else:
            # Extract product_id with fallback logic
            product_id = (
                doc.get("product", {}).get("model")
                or doc.get("product", {}).get("serialNumber")
                or doc.get("product", {}).get("batchOrLot")
                or doc.get("attributes", {}).get("model")
                or doc.get("attributes", {}).get("modelNumber")
                or doc.get("product_id")
                or dpp_id
            )
            
            # Build DPP URL
            dpp_url = doc.get("dppUrl") or f"http://api:8000/dpp/{dpp_id}"
            
            # Create header
            dpp = Dpp(
                dpp_id=dpp_id,
                product_id=product_id,
                dpp_url=dpp_url
            )
            db.add(dpp)
            db.flush()
        
        # Add version 1 (check if version exists)
        existing_version = db.query(DppVersion).filter(
            DppVersion.dpp_id == dpp_id,
            DppVersion.version == 1
        ).first()
        
        if not existing_version:
            version = DppVersion(
                dpp_id=dpp_id,
                version=1,
                payload=doc
            )
            db.add(version)
            created += 1
    
    db.commit()
    return created, skipped


def seed_lego_duck_data(force: bool = False) -> None:
    """
    Seed database with Lego Duck sample data.
    
    Args:
        force: If True, re-seed even if data already exists
    """
    # Initialize database tables
    init_db()
    
    # Find the seed file
    # Path: api/dpp_api/seed_data.py -> api -> project_root -> seed/postgres
    seed_file = Path(__file__).resolve().parents[2] / "seed" / "postgres" / "lego-duck-sample-dpps.ndjson"
    
    if not seed_file.exists():
        print(f"❌ Seed file not found: {seed_file}")
        return
    
    print(f"📦 Seeding database from: {seed_file.name}")
    print(f"   Database: {settings.environment} mode")
    print(f"   URL: {settings.resolved_database_url}")
    
    with SessionLocal() as db:
        # Check if data already exists
        existing_count = db.query(Dpp).count()
        
        if existing_count > 0 and not force:
            print(f"ℹ️  Database already contains {existing_count} DPP records")
            print("   Skipping seed (use --force to re-seed)")
            return
        
        created, skipped = seed_from_ndjson(db, seed_file, skip_existing=not force)
        
        total_count = db.query(Dpp).count()
        print("✅ Seeding complete!")
        print(f"   Created: {created} records")
        print(f"   Skipped: {skipped} records")
        print(f"   Total in DB: {total_count} records")


if __name__ == "__main__":
    import sys
    
    force = "--force" in sys.argv or "-f" in sys.argv
    
    print("🌱 DPP Database Seeding Tool")
    print("=" * 60)
    print()
    
    try:
        seed_lego_duck_data(force=force)
        print()
        print("💡 You can now query DPPs via API:")
        print("   curl http://localhost:8000/dpp/did:web:dpp.brickquack.com:product:lego-duck:item-SN-2025-LD-001234")
    except Exception as e:
        print(f"❌ Error seeding database: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
