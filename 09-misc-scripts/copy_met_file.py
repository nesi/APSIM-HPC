import csv
import shutil
from pathlib import Path
 
# Define the source and destination directories using Linux file paths
source_dir = Path("/agr/persist/projects/2024_apsim_improvements/InputData/data01Jan1972To31Dec2025/MET")
dest_dir = Path("/agr/persist/projects/2024_apsim_improvements/InputData/r8012_20260320_NitrateIndicator/batch_failed")
csv_file = dest_dir / "AgentInfo.csv"
 
# Keep track of files to avoid copying the same file multiple times
processed_files = set()
copied_count = 0
not_found = []
 
# Open the CSV file (using utf-8-sig to handle optional BOM at the start of the file)
with open(csv_file, mode='r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    
    for row in reader:
        part1 = row.get('Part1')
        # Skip empty rows
        if not part1:
            continue
            
        part1 = part1.strip()
        
        # Ensure the filename ends with exactly one .met extension
        if part1.lower().endswith('.met'):
            file_name = part1
        else:
            file_name = f"{part1}.met"
            
        # Skip if we already processed this exact file
        if file_name in processed_files:
            continue
            
        processed_files.add(file_name)
        
        source_path = source_dir / file_name
        dest_path = dest_dir / file_name
        
        # Copy the file if it exists in the source directory
        if source_path.exists():
            # shutil.copy2 preserves file metadata like timestamps
            shutil.copy2(source_path, dest_path)
            copied_count += 1
        else:
            not_found.append(file_name)
 
# Print a summary report of the operation
print(f"Job finished! Successfully copied {copied_count} files.")
if not_found:
    print(f"WARNING: Could not find {len(not_found)} files in the source directory:")
    # Print up to the first 10 missing files to avoid flooding the console
    for missing in not_found[:10]:
        print(f" - {missing}")
    if len(not_found) > 10:
        print(" ... (and more)")