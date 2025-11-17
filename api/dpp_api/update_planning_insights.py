"""
Update DPP planning insights from CSV file.
Reads planning data from CSV and updates DPPs via API.
"""
from __future__ import annotations

import csv
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional
import requests
from datetime import datetime, timezone

from .models import SessionLocal, get_latest_dpp_version
from .config import settings

# Setup logging
logger = logging.getLogger(__name__)


def read_planning_csv(csv_path: Path) -> List[Dict]:
    """
    Read planning insights CSV file.
    Returns list of records with planning data.
    """
    records = []
    with open(csv_path, "r", encoding="utf-8") as f:
        # CSV uses semicolon as delimiter
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            # Skip empty rows
            if not row.get("PRDID"):
                continue
            records.append(row)
    return records


def map_csv_to_planning_insights(records: List[Dict]) -> Dict[str, Dict]:
    """
    Map CSV records to planning insights structure.
    Groups by product ID and aggregates location-specific data.
    
    Returns:
        Dict mapping product_id to planning insights object
    """
    product_insights = {}
    
    for record in records:
        prd_id = record.get("PRDID")
        if not prd_id:
            continue
            
        if prd_id not in product_insights:
            product_insights[prd_id] = {
                "locations": [],
                "transportOptimization": "",
                "carbonFootprintReduction": "",
            }
        
        loc_from = record.get("LOCFR", "")
        loc_id = record.get("LOCID", "")
        
        # Parse numeric values, handling empty strings
        try:
            adjusted_transport = float(record.get("ADJUSTEDTRANSPORT", 0) or 0)
        except (ValueError, TypeError):
            adjusted_transport = 0
            
        try:
            transport = float(record.get("TRANSPORT", 0) or 0)
        except (ValueError, TypeError):
            transport = 0
            
        try:
            prev_footprint = float(record.get("SC1STOREDPREVTRANSPFOOTPRFINAL", 0) or 0)
        except (ValueError, TypeError):
            prev_footprint = 0
            
        try:
            current_footprint = float(record.get("SC1STOREDTRANSPFOOTPRFINAL", 0) or 0)
        except (ValueError, TypeError):
            current_footprint = 0
        
        # Add location-specific insights
        location_insight = {
            "locationFrom": loc_from,
            "locationId": loc_id,
            "adjustedTransportQuantity": adjusted_transport,
            "standardTransportQuantity": transport,
            "previousTransportFootprint": prev_footprint,
            "currentTransportFootprint": current_footprint,
        }
        
        # Calculate savings/improvements
        if transport > 0 and adjusted_transport > 0:
            savings_pct = ((transport - adjusted_transport) / transport) * 100
            location_insight["quantitySavings"] = f"{savings_pct:.1f}%"
        
        if prev_footprint > 0 and current_footprint > 0:
            footprint_change = ((current_footprint - prev_footprint) / prev_footprint) * 100
            location_insight["footprintChange"] = f"{footprint_change:+.1f}%"
        
        product_insights[prd_id]["locations"].append(location_insight)
    
    # Generate summary insights for each product
    for prd_id, insights in product_insights.items():
        locations = insights["locations"]
        if not locations:
            continue
        
        # Calculate total savings
        total_savings = sum(
            loc.get("adjustedTransportQuantity", 0) - loc.get("standardTransportQuantity", 0)
            for loc in locations
            if loc.get("adjustedTransportQuantity") and loc.get("standardTransportQuantity")
        )
        
        if total_savings < 0:
            insights["transportOptimization"] = (
                f"Optimized transport routes achieving {abs(total_savings):.0f} quantity units reduction "
                f"across {len(locations)} distribution locations"
            )
        
        # Calculate transport carbon footprint totals
        total_current_transport_footprint = sum(
            loc.get("currentTransportFootprint", 0)
            for loc in locations
        )
        
        total_previous_transport_footprint = sum(
            loc.get("previousTransportFootprint", 0)
            for loc in locations
        )
        
        # Add transport carbon footprint to insights
        insights["transportCarbonFootprint"] = {
            "current": round(total_current_transport_footprint, 2),
            "previous": round(total_previous_transport_footprint, 2),
            "unit": "kg CO2e",
            "scope": "transport-distribution"
        }
        
        # Calculate absolute and percentage change
        footprint_absolute_change = total_current_transport_footprint - total_previous_transport_footprint
        
        if total_previous_transport_footprint > 0:
            footprint_percentage_change = (footprint_absolute_change / total_previous_transport_footprint) * 100
            insights["transportCarbonFootprint"]["change"] = round(footprint_percentage_change, 1)
            insights["transportCarbonFootprint"]["changeAbsolute"] = round(footprint_absolute_change, 2)
        
        # Calculate average footprint change
        footprint_changes = [
            ((loc.get("currentTransportFootprint", 0) - loc.get("previousTransportFootprint", 0)) 
             / loc.get("previousTransportFootprint", 1))
            for loc in locations
            if loc.get("previousTransportFootprint", 0) > 0
        ]
        
        if footprint_changes:
            avg_change = (sum(footprint_changes) / len(footprint_changes)) * 100
            if avg_change < 0:
                insights["carbonFootprintReduction"] = (
                    f"Transport carbon footprint reduced by {abs(avg_change):.1f}% "
                    f"through route optimization (saving {abs(footprint_absolute_change):.1f} kg CO2e)"
                )
            elif avg_change > 0:
                insights["carbonFootprintReduction"] = (
                    f"Transport carbon footprint increased by {avg_change:.1f}% "
                    f"(+{footprint_absolute_change:.1f} kg CO2e - new routes or demand increase)"
                )
    
    return product_insights


def find_dpp_id_by_product(product_id: str) -> Optional[str]:
    """
    Find DPP ID by product model/ID.
    Searches database for matching product_id or model in payload.
    """
    with SessionLocal() as db:
        from .models import Dpp, DppVersion
        
        # Search by product_id field (normalized)
        normalized_id = product_id.upper().replace("-", "").replace("_", "")
        
        dpps = db.query(Dpp).all()
        for dpp in dpps:
            # Check if product_id matches
            dpp_product_normalized = dpp.product_id.upper().replace("-", "").replace("_", "")
            if dpp_product_normalized == normalized_id:
                return dpp.dpp_id
        
        # Search by model in latest version payload
        versions = db.query(DppVersion).order_by(DppVersion.version.desc()).all()
        for v in versions:
            payload = v.payload or {}
            product = payload.get("product", {})
            model = product.get("model", "")
            
            # Direct match
            if model == product_id:
                return v.dpp_id
            
            # Normalized match
            model_normalized = model.upper().replace("-", "").replace("_", "")
            if model_normalized == normalized_id:
                return v.dpp_id
    
    return None


def update_dpp_planning_insights(
    dpp_id: str,
    planning_insights: Dict,
    api_base: str = "http://localhost:8000",
) -> bool:
    """
    Update DPP with new planning insights by creating a new version.
    
    Args:
        dpp_id: The DPP ID to update
        planning_insights: Planning insights data to add/update
        api_base: API base URL
        
    Returns:
        True if successful, False otherwise
    """
    # Fetch current DPP payload
    with SessionLocal() as db:
        latest = get_latest_dpp_version(db, dpp_id)
        if not latest:
            logger.error(f"DPP not found: {dpp_id}")
            return False
        
        # Clone payload and update planning insights
        new_payload = dict(latest.payload)
        
        # Merge with existing planning insights (if any)
        existing_insights = new_payload.get("planningInsights", {})
        
        # Update with new data
        updated_insights = {**existing_insights, **planning_insights}
        new_payload["planningInsights"] = updated_insights
        
        # Update timestamps
        new_payload["updatedAt"] = datetime.now(timezone.utc).isoformat()
        
        # Create new version directly in DB (simpler for local)
        from .models import DppVersion, Dpp
        
        next_version = latest.version + 1
        new_version = DppVersion(
            dpp_id=dpp_id,
            version=next_version,
            valid_from=datetime.now(timezone.utc),
            payload=new_payload,
        )
        
        # Update header timestamp
        dpp = db.query(Dpp).filter(Dpp.dpp_id == dpp_id).first()
        if dpp:
            dpp.updated_at = datetime.now(timezone.utc)
        
        db.add(new_version)
        db.commit()
        
        logger.info(f"✅ Updated {dpp_id} -> v{next_version}")
        return True


def update_all_planning_insights(csv_path: Optional[Path] = None, dry_run: bool = False) -> None:
    """
    Main function to update all DPPs with planning insights from CSV.
    
    Args:
        csv_path: Path to CSV file. If None, uses default location.
        dry_run: If True, print what would be updated without actually updating
    """
    # Default CSV path
    if csv_path is None:
        csv_path = Path(__file__).resolve().parents[1] / "drop" / "SSCP1__PRODLOCLOCFR_TEMPLATE.csv"
    
    if not csv_path.exists():
        logger.error(f"CSV file not found: {csv_path}")
        return
    
    logger.info("📊 Reading planning insights from CSV...")
    logger.info(f"   File: {csv_path.name}")
    
    # Read and parse CSV
    records = read_planning_csv(csv_path)
    logger.info(f"   Records: {len(records)}")
    
    # Map to planning insights structure
    product_insights = map_csv_to_planning_insights(records)
    logger.info(f"   Products: {len(product_insights)}")
    logger.info("")
    
    # Update each product's DPP
    updated_count = 0
    not_found_count = 0
    
    for product_id, insights in product_insights.items():
        logger.info(f"Processing {product_id}...")
        
        # Find DPP ID
        dpp_id = find_dpp_id_by_product(product_id)
        if not dpp_id:
            logger.warning(f"  ⚠️  No DPP found for product: {product_id}")
            not_found_count += 1
            continue
        
        logger.debug(f"  Found DPP: {dpp_id}")
        
        if dry_run:
            logger.info(f"  [DRY RUN] Would update with:")
            logger.debug(f"    {json.dumps(insights, indent=4)}")
        else:
            # Update DPP
            success = update_dpp_planning_insights(dpp_id, insights)
            if success:
                updated_count += 1
        
        logger.info("")
    
    # Summary
    logger.info("=" * 60)
    logger.info("📈 Planning Insights Update Summary")
    logger.info("=" * 60)
    if dry_run:
        logger.info("   DRY RUN - No changes made")
    logger.info(f"   Updated: {updated_count} DPPs")
    logger.info(f"   Not found: {not_found_count} products")
    logger.info("")


if __name__ == "__main__":
    import sys
    
    # Setup console logging for standalone script
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    dry_run = "--dry-run" in sys.argv
    
    logger.info("🔄 DPP Planning Insights Update Tool")
    logger.info("=" * 60)
    logger.info("")
    
    try:
        update_all_planning_insights(dry_run=dry_run)
        logger.info("✅ Update complete!")
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        logger.exception("Full traceback:")
        sys.exit(1)
