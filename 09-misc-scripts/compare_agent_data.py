import sqlite3
import csv
import os

def run_comparison(db_paths, csv_path, output_path=None):
    """
    Compares a CSV file with multiple database files and counts records.
    
    Args:
        db_paths (list): List of paths to .db files.
        csv_path (str): Path to the input .csv file (with Part1, Part2 columns).
        output_path (str): Path to save the output .csv file.
    """
    if output_path is None:
        base_dir = os.path.dirname(csv_path)
        output_path = os.path.join(base_dir, 'AgentRecordCounts.csv')
    else:
        output_path = os.path.join(output_path, 'AgentRecordCounts.csv')


    print(f"Starting comparison with {len(db_paths)} database(s)...")
    db_counts = {}

    # 1. Aggregate counts from all database files
    for db_path in db_paths:
        if not os.path.exists(db_path):
            print(f"Warning: Database file not found at {db_path}. Skipping.")
            continue
            
        print(f"Reading counts from: {os.path.basename(db_path)}...")
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            # We strip '.met' from the Agent column to match CSV's Part1
            query = """
                SELECT 
                    REPLACE(Agent, '.met', '') as AgentNo, 
                    Soil, 
                    COUNT(*) as RecordNo 
                FROM Report 
                GROUP BY AgentNo, Soil
            """
            cursor.execute(query)
            for row in cursor.fetchall():
                agent_no, soil, count = row
                key = (str(agent_no), str(soil))
                # Add count to any existing total for this Agent/Soil combo
                db_counts[key] = db_counts.get(key, 0) + count
            conn.close()
        except Exception as e:
            print(f"Error reading database {db_path}: {e}")

    # 2. Process the CSV file
    print(f"Processing CSV: {os.path.basename(csv_path)}")
    if not os.path.exists(csv_path):
        print(f"Error: CSV file not found at {csv_path}")
        return

    print(csv_path)
    try:
        with open(csv_path, mode='r', encoding='utf-8-sig') as infile:
            reader = csv.DictReader(infile)
            fieldnames = ['AgentNo', 'Soil', 'RecordNo']
            
            with open(output_path, mode='w', encoding='utf-8', newline='') as outfile:
                writer = csv.DictWriter(outfile, fieldnames=fieldnames)
                writer.writeheader()
                
                rows_processed = 0
                for row in reader:
                    # Input headers: Part1, Part2
                    agent_no = str(row['Part1'])
                    soil = str(row['Part2'])
                    
                    # Look up count in our aggregated dictionary
                    count = db_counts.get((agent_no, soil), 0)
                    
                    writer.writerow({
                        'AgentNo': agent_no,
                        'Soil': soil,
                        'RecordNo': count
                    })
                    rows_processed += 1
                    
        print(f"Done! Processed {rows_processed} rows and saved to {output_path}")
        
    except Exception as e:
        print(f"Error processing files: {e}")

if __name__ == "__main__":
    # Example usage with the current files
    db_dir = r'/agr/scratch/projects/2024_apsim_improvements/runFolders/r8012_20260320_NitrateIndicator'
    csv_dir = r'/agr/persist/projects/2024_apsim_improvements/ProductionVersion/APSIM-HPC/agent-compare'

    # You can add more DB files to this list
    databases = [
        os.path.join(db_dir, 'batch_1/MasterDB.db'),
        os.path.join(db_dir, 'batch_2/MasterDB.db'),
        os.path.join(db_dir, 'batch_3/MasterDB.db'),
        os.path.join(db_dir, 'batch_4/MasterDB.db'),
        os.path.join(db_dir, 'batch_5/MasterDB.db')
    ]
    
    
    input_csv = os.path.join(csv_dir, 'AgentInfo.csv')
    
    run_comparison(databases, input_csv, csv_dir)
