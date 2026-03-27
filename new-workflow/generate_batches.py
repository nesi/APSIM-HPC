#!/usr/bin/env python3
"""
Generate batch CSV files for APSIM's --batch mode.

Reads soil/weather combinations from a user-supplied CSV file
(column 1 = weather file name without .met, column 2 = soil name),
validates soils against the library, and splits into batch CSV files
of configurable size.

Usage:
    python generate_batches.py
    python generate_batches.py --config my_config.yaml
"""

import argparse
import csv
import os
import re
import sys
from pathlib import Path

import yaml


def load_config(config_path: str = "config.yaml") -> dict:
    """Load workflow configuration from YAML file."""
    config_path = Path(config_path)
    if not config_path.exists():
        print(f"ERROR: Config file not found: {config_path}")
        sys.exit(1)

    with open(config_path, "r") as f:
        return yaml.safe_load(f)


def read_combinations(csv_path: str) -> list[tuple[str, str]]:
    """
    Read weather/soil combinations from a CSV file.
    Column 1: weather file name (without .met extension)
    Column 2: soil name
    Returns list of (weather_file, soil_name) tuples.
    """
    WEATHER_HEADERS = {"agent", "weather", "weather_file", "weatherfile", "met", "weather-file"}
    SOIL_HEADERS = {"soil", "soilname", "soil_name", "soil-name"}

    combos = []
    with open(csv_path, "r", newline="") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 2:
                continue
            col1 = row[0].strip()
            col2 = row[1].strip()
            if not col1 or not col2:
                continue
            # Skip header row
            if col1.lower() in WEATHER_HEADERS or col2.lower() in SOIL_HEADERS:
                continue
            combos.append((col1, col2))
    return combos


def validate_soils(soil_names: list[str], library_path: str) -> list[str]:
    """
    Validate soil names against those available in the soil library.
    Returns list of valid soil names, prints warnings for invalid ones.
    """
    library_path = Path(library_path)
    if not library_path.exists():
        print(f"WARNING: Soil library not found: {library_path}")
        print("Skipping soil validation - all soil names will be used.")
        return soil_names

    # Parse soil library JSON for LocalName fields
    content = library_path.read_text(encoding="utf-8", errors="replace")
    available = set()
    for match in re.finditer(r'"LocalName"\s*:\s*"([^"]+)"', content):
        available.add(match.group(1).strip())

    valid = []
    for soil in soil_names:
        if soil in available:
            valid.append(soil)
        else:
            print(f"  WARNING: Soil '{soil}' not found in library - skipping")

    print(f"  Validated {len(valid)}/{len(soil_names)} soil names")
    return valid


def build_design_rows(
    combinations: list[tuple[str, str]],
) -> list[dict]:
    """
    Convert (weather, soil) tuples into batch-ready dicts.
    Each entry has keys matching the batch CSV column headers.
    """
    rows = []
    for weather, soil in combinations:
        sim_name = f"{weather}_{soil.replace(' ', '')}"
        rows.append(
            {
                "soil-name": soil,
                "weather-file": weather,
                "sim-name": sim_name,
            }
        )
    return rows


def split_and_write_batches(
    rows: list[dict], output_dir: str, rows_per_batch: int
) -> list[str]:
    """
    Split design rows into batch CSV files and write them.
    Adds a 'batch-name' column so the command template can load
    the correct batch-specific .apsimx copy.
    Returns list of batch CSV file paths (relative to output_dir's parent).
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    batch_files = []
    total_batches = (len(rows) + rows_per_batch - 1) // rows_per_batch
    fieldnames = ["batch-name", "soil-name", "weather-file", "sim-name"]

    for batch_idx in range(total_batches):
        start = batch_idx * rows_per_batch
        end = min(start + rows_per_batch, len(rows))
        batch_rows = rows[start:end]

        batch_name = f"batch_{batch_idx + 1:04d}"
        batch_filename = f"{batch_name}.csv"
        batch_path = output_dir / batch_filename

        # Add batch-name to each row
        for row in batch_rows:
            row["batch-name"] = batch_name

        with open(batch_path, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, lineterminator="\n")
            writer.writeheader()
            writer.writerows(batch_rows)

        batch_files.append(str(batch_path))

    return batch_files


def main():
    parser = argparse.ArgumentParser(
        description="Generate APSIM batch CSV files from soil/weather factorial design"
    )
    parser.add_argument(
        "--config",
        default="config.yaml",
        help="Path to config.yaml (default: config.yaml)",
    )
    args = parser.parse_args()

    config = load_config(args.config)

    print("=" * 60)
    print("APSIM Batch CSV Generator")
    print("=" * 60)

    # Read combinations
    combos_csv = config["combinations_csv"]
    print(f"\n[1/4] Reading combinations from: {combos_csv}")
    combinations = read_combinations(combos_csv)
    print(f"  Found {len(combinations)} weather/soil combinations")

    if not combinations:
        print("ERROR: No combinations found. Check your combinations_csv.")
        sys.exit(1)

    # Validate soils
    all_soils = list(dict.fromkeys(soil for _, soil in combinations))  # unique, order-preserved
    print(f"\n[2/4] Validating {len(all_soils)} unique soil names against: {config['soil_library']}")
    valid_soils = set(validate_soils(all_soils, config["soil_library"]))

    if not valid_soils:
        print("ERROR: No valid soil names remain after validation.")
        sys.exit(1)

    # Filter combinations to only valid soils
    combinations = [(w, s) for w, s in combinations if s in valid_soils]
    print(f"  {len(combinations)} combinations remain after soil validation")

    # Build design rows
    print(f"\n[3/4] Building design rows from {len(combinations)} combinations")
    rows = build_design_rows(combinations)

    # Split and write batch CSVs
    rows_per_batch = config.get("rows_per_batch", 500)
    output_dir = config.get("output_dir", "batches")
    print(f"\n[4/4] Writing batch CSVs ({rows_per_batch} rows each) to: {output_dir}/")
    batch_files = split_and_write_batches(rows, output_dir, rows_per_batch)

    print(f"\n  Created {len(batch_files)} batch files:")
    for bf in batch_files:
        print(f"    - {bf}")

    # Write a manifest for Snakemake to discover batch files
    manifest_path = Path(output_dir) / "batch_manifest.txt"
    with open(manifest_path, "w") as f:
        for bf in batch_files:
            f.write(f"{bf}\n")

    print(f"\n  Manifest written to: {manifest_path}")
    print(f"\n{'=' * 60}")
    print(f"Done! {len(batch_files)} batch CSV files ready.")
    print(f"Next: run 'snakemake --profile slurm' to execute.")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
