#!/usr/bin/env python3
"""
Validate APSIM batch results.

Queries each batch .db file (sqlite) to check which simulations completed
vs. which are missing, cross-referencing against the batch CSVs.

Usage:
    python scripts/validate_results.py
    python scripts/validate_results.py --config config.yaml --verbose
"""

import argparse
import csv
import sqlite3
import sys
from pathlib import Path

import yaml


def load_config(config_path: str = "config.yaml") -> dict:
    with open(config_path) as f:
        return yaml.safe_load(f)


def get_expected_simulations(batch_dir: str) -> dict[str, list[str]]:
    """Read all batch CSVs and return {batch_id: [sim_name, ...]}."""
    expected = {}
    for csv_file in sorted(Path(batch_dir).glob("batch_*.csv")):
        batch_id = csv_file.stem
        with open(csv_file, newline="") as f:
            reader = csv.DictReader(f)
            expected[batch_id] = [row["sim-name"] for row in reader]
    return expected


def query_db_simulations(db_path: Path) -> set[str]:
    """Query a .db file for completed simulation names."""
    if not db_path.exists() or db_path.stat().st_size == 0:
        return set()
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute("SELECT DISTINCT Name FROM _Simulations")
        sims = {row[0] for row in cursor.fetchall()}
        conn.close()
        return sims
    except sqlite3.Error as e:
        print(f"  WARNING: Could not read {db_path}: {e}")
        return set()


def main():
    parser = argparse.ArgumentParser(description="Validate APSIM batch results")
    parser.add_argument("--config", default="config.yaml")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    config = load_config(args.config)
    batch_dir = config.get("output_dir", "batches")
    db_output_dir = config.get("db_output_dir", "OutputDatabases")

    print("=" * 60)
    print("APSIM Results Validation")
    print("=" * 60)

    # Get expected simulations from batch CSVs
    expected = get_expected_simulations(batch_dir)
    total_expected = sum(len(sims) for sims in expected.values())
    print(f"\nBatch files:         {len(expected)}")
    print(f"Expected simulations: {total_expected}")

    # Query each .db and compare
    results = []
    total_found = 0

    for batch_id, sim_names in sorted(expected.items()):
        db_path = Path(db_output_dir) / f"{batch_id}.db"
        found_sims = query_db_simulations(db_path)
        batch_found = 0

        for sim_name in sim_names:
            # Experiment factorial expands sim-name into multiple
            # simulations prefixed with the sim-name
            matching = [s for s in found_sims if s.startswith(sim_name)]
            if matching:
                results.append((sim_name, batch_id, "COMPLETED", len(matching)))
                total_found += 1
                batch_found += 1
            else:
                results.append((sim_name, batch_id, "MISSING", 0))

        status = "OK" if batch_found == len(sim_names) else "INCOMPLETE"
        if args.verbose or status == "INCOMPLETE":
            print(f"  {batch_id}: {batch_found}/{len(sim_names)} simulations [{status}]")

    # Summary
    missing = total_expected - total_found
    print(f"\n--- Summary ---")
    print(f"  Completed: {total_found}/{total_expected}")
    print(f"  Missing:   {missing}")

    if args.verbose and missing > 0:
        print(f"\n--- Missing simulations ---")
        for sim_name, batch_id, status, count in results:
            if status == "MISSING":
                print(f"  {sim_name} (from {batch_id})")

    # Write detailed report
    report_path = Path(db_output_dir) / "validation_report.csv"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["sim_name", "batch_id", "status", "sim_count"])
        for row in results:
            writer.writerow(row)

    print(f"\nDetailed report: {report_path}")

    success_rate = total_found / total_expected * 100 if total_expected else 0
    print(f"Success rate: {success_rate:.1f}%")

    return 0 if missing == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
