"""
File system watcher for planning insights CSV files.
Monitors drop folder, processes new CSVs, and archives them with manifest.
"""
from __future__ import annotations

import json
import shutil
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Optional
import hashlib

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileCreatedEvent

from .update_planning_insights import (
    read_planning_csv,
    map_csv_to_planning_insights,
    find_dpp_id_by_product,
    update_dpp_planning_insights,
)


class CSVProcessingResult:
    """Result of processing a CSV file."""
    
    def __init__(self, csv_path: Path):
        self.csv_path = csv_path
        self.start_time = datetime.now(timezone.utc)
        self.end_time: Optional[datetime] = None
        self.success = False
        self.records_read = 0
        self.products_found = 0
        self.dpps_updated = 0
        self.dpps_not_found = 0
        self.errors: list[str] = []
        self.file_hash: Optional[str] = None
        
    def complete(self):
        """Mark processing as complete."""
        self.end_time = datetime.now(timezone.utc)
        
    def duration_seconds(self) -> float:
        """Calculate processing duration in seconds."""
        if self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return 0.0
        
    def to_dict(self) -> Dict:
        """Convert result to dictionary for manifest."""
        return {
            "file": self.csv_path.name,
            "file_hash": self.file_hash,
            "processed_at": self.start_time.isoformat(),
            "completed_at": self.end_time.isoformat() if self.end_time else None,
            "duration_seconds": self.duration_seconds(),
            "success": self.success,
            "statistics": {
                "records_read": self.records_read,
                "products_found": self.products_found,
                "dpps_updated": self.dpps_updated,
                "dpps_not_found": self.dpps_not_found,
            },
            "errors": self.errors,
        }


def calculate_file_hash(file_path: Path) -> str:
    """Calculate SHA256 hash of file."""
    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256.update(chunk)
    return sha256.hexdigest()


def process_csv_file(csv_path: Path) -> CSVProcessingResult:
    """
    Process a single CSV file and update DPPs.
    
    Args:
        csv_path: Path to CSV file to process
        
    Returns:
        Processing result with statistics
    """
    result = CSVProcessingResult(csv_path)
    
    try:
        # Calculate file hash
        result.file_hash = calculate_file_hash(csv_path)
        
        print(f"📊 Processing {csv_path.name}...")
        print(f"   Hash: {result.file_hash[:16]}...")
        
        # Read CSV
        records = read_planning_csv(csv_path)
        result.records_read = len(records)
        print(f"   Records: {result.records_read}")
        
        # Map to planning insights
        product_insights = map_csv_to_planning_insights(records)
        result.products_found = len(product_insights)
        print(f"   Products: {result.products_found}")
        print()
        
        # Update each product
        for product_id, insights in product_insights.items():
            print(f"  Processing {product_id}...")
            
            # Find DPP
            dpp_id = find_dpp_id_by_product(product_id)
            if not dpp_id:
                print(f"    ⚠️  No DPP found")
                result.dpps_not_found += 1
                result.errors.append(f"Product {product_id}: DPP not found")
                continue
            
            print(f"    Found: {dpp_id}")
            
            # Update DPP
            try:
                success = update_dpp_planning_insights(dpp_id, insights)
                if success:
                    result.dpps_updated += 1
                    print(f"    ✅ Updated")
                else:
                    result.errors.append(f"Product {product_id}: Update failed")
                    print(f"    ❌ Failed")
            except Exception as e:
                result.errors.append(f"Product {product_id}: {str(e)}")
                print(f"    ❌ Error: {e}")
        
        # Mark as successful if we updated at least one DPP
        result.success = result.dpps_updated > 0
        
    except Exception as e:
        result.errors.append(f"Processing error: {str(e)}")
        print(f"❌ Error processing file: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        result.complete()
    
    return result


def archive_csv_with_manifest(
    csv_path: Path,
    result: CSVProcessingResult,
    drop_folder: Path,
) -> None:
    """
    Archive CSV file with processing manifest.
    
    Args:
        csv_path: Path to CSV file to archive
        result: Processing result
        drop_folder: Drop folder containing processed/ subdirectory
    """
    # Create processed folder if it doesn't exist
    processed_folder = drop_folder / "processed"
    processed_folder.mkdir(exist_ok=True)
    
    # Create timestamped subfolder for this batch
    timestamp = result.start_time.strftime("%Y%m%d_%H%M%S")
    batch_folder = processed_folder / f"{timestamp}_{csv_path.stem}"
    batch_folder.mkdir(exist_ok=True)
    
    # Copy CSV to archive
    archived_csv = batch_folder / csv_path.name
    shutil.copy2(csv_path, archived_csv)
    print(f"📁 Archived: {archived_csv}")
    
    # Create manifest
    manifest = {
        "manifest_version": "1.0",
        "processing_result": result.to_dict(),
    }
    
    manifest_path = batch_folder / "manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"📄 Manifest: {manifest_path}")
    
    # Delete original CSV
    csv_path.unlink()
    print(f"🗑️  Deleted: {csv_path.name}")


def is_already_processed(csv_path: Path, drop_folder: Path) -> bool:
    """
    Check if CSV file has already been processed by comparing hash.
    
    Args:
        csv_path: Path to CSV file to check
        drop_folder: Drop folder containing processed/ subdirectory
        
    Returns:
        True if file has already been processed
    """
    processed_folder = drop_folder / "processed"
    if not processed_folder.exists():
        return False
    
    # Calculate current file hash
    current_hash = calculate_file_hash(csv_path)
    
    # Check all manifests for matching hash
    for manifest_file in processed_folder.rglob("manifest.json"):
        try:
            with open(manifest_file, "r", encoding="utf-8") as f:
                manifest = json.load(f)
                stored_hash = manifest.get("processing_result", {}).get("file_hash")
                if stored_hash == current_hash:
                    print(f"⚠️  File already processed: {csv_path.name}")
                    print(f"   Hash: {current_hash[:16]}...")
                    print(f"   Previous: {manifest_file.parent.name}")
                    return True
        except Exception:
            # Ignore manifest read errors
            pass
    
    return False


class PlanningInsightsHandler(FileSystemEventHandler):
    """
    Handles file system events for planning insights CSV files.
    """
    
    def __init__(self, drop_folder: Path, debounce_seconds: float = 2.0):
        """
        Initialize handler.
        
        Args:
            drop_folder: Path to folder to watch
            debounce_seconds: Seconds to wait after file creation before processing
        """
        super().__init__()
        self.drop_folder = drop_folder
        self.debounce_seconds = debounce_seconds
        self.pending_files: Dict[str, float] = {}
        
    def on_created(self, event: FileCreatedEvent) -> None:
        """Handle file creation events."""
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        
        # Only process CSV files
        if file_path.suffix.lower() != ".csv":
            return
        
        # Ignore files in processed subfolder
        if "processed" in file_path.parts:
            return
        
        print(f"\n🔔 New file detected: {file_path.name}")
        
        # Add to pending with timestamp
        self.pending_files[str(file_path)] = time.time()
    
    def process_pending_files(self) -> None:
        """Process files that have been pending long enough (debounce)."""
        current_time = time.time()
        files_to_process = []
        
        for file_path_str, created_time in list(self.pending_files.items()):
            if current_time - created_time >= self.debounce_seconds:
                files_to_process.append(file_path_str)
                del self.pending_files[file_path_str]
        
        for file_path_str in files_to_process:
            file_path = Path(file_path_str)
            
            # Check if file still exists
            if not file_path.exists():
                print(f"⚠️  File disappeared: {file_path.name}")
                continue
            
            # Check if already processed
            if is_already_processed(file_path, self.drop_folder):
                # Move to processed without reprocessing
                timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
                processed_folder = self.drop_folder / "processed"
                processed_folder.mkdir(exist_ok=True)
                duplicate_folder = processed_folder / f"{timestamp}_duplicate_{file_path.stem}"
                duplicate_folder.mkdir(exist_ok=True)
                shutil.move(str(file_path), str(duplicate_folder / file_path.name))
                print(f"   Moved to: {duplicate_folder}")
                continue
            
            # Process the file
            print(f"\n{'='*60}")
            print(f"🚀 Processing: {file_path.name}")
            print(f"{'='*60}\n")
            
            result = process_csv_file(file_path)
            
            # Archive with manifest
            print(f"\n{'='*60}")
            print("📦 Archiving...")
            print(f"{'='*60}")
            archive_csv_with_manifest(file_path, result, self.drop_folder)
            
            # Print summary
            print(f"\n{'='*60}")
            print("✅ Processing Complete")
            print(f"{'='*60}")
            print(f"Duration: {result.duration_seconds():.2f}s")
            print(f"Success: {result.success}")
            print(f"Updated: {result.dpps_updated} DPPs")
            if result.errors:
                print(f"Errors: {len(result.errors)}")
                for error in result.errors[:3]:  # Show first 3 errors
                    print(f"  - {error}")
            print(f"{'='*60}\n")


def watch_folder(drop_folder: Path, debounce_seconds: float = 2.0) -> None:
    """
    Watch folder for new CSV files and process them.
    
    Args:
        drop_folder: Path to folder to watch
        debounce_seconds: Seconds to wait after file creation before processing
    """
    # Create drop folder if it doesn't exist
    drop_folder.mkdir(parents=True, exist_ok=True)
    
    print("👁️  Planning Insights File Watcher")
    print("="*60)
    print(f"Watching: {drop_folder}")
    print(f"Debounce: {debounce_seconds}s")
    print("="*60)
    print("\nPress Ctrl+C to stop\n")
    
    # Create event handler and observer
    event_handler = PlanningInsightsHandler(drop_folder, debounce_seconds)
    observer = Observer()
    observer.schedule(event_handler, str(drop_folder), recursive=False)
    observer.start()
    
    try:
        while True:
            # Check for pending files to process
            event_handler.process_pending_files()
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\n\n🛑 Stopping watcher...")
        observer.stop()
    
    observer.join()
    print("✅ Watcher stopped")


if __name__ == "__main__":
    import sys
    
    # Get drop folder from command line or use default
    if len(sys.argv) > 1:
        drop_folder = Path(sys.argv[1])
    else:
        drop_folder = Path(__file__).resolve().parents[1] / "drop"
    
    # Get debounce from command line or use default
    debounce_seconds = 2.0
    if len(sys.argv) > 2:
        try:
            debounce_seconds = float(sys.argv[2])
        except ValueError:
            print(f"⚠️  Invalid debounce value, using default: {debounce_seconds}s")
    
    watch_folder(drop_folder, debounce_seconds)
