#!/bin/bash

#SBATCH --job-name=apsim_models
#SBATCH --output=slurmlogs/%j.out
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=16:00:00

module load Apptainer
export APPTAINER_BIND="/agr/scratch,/agr/persist"
export APPTAINER_CMD="apptainer exec /agr/persist/projects/2024_apsim_improvements/apsim-simulations/container/apsim-2024.09.7579.0.aimg"

# Directory containing the .txt files
WORK_DIR="."

# Directory for failed files
FAILED_DIR="$WORK_DIR/FAILED"

# Create FAILED directory if it doesn't exist
mkdir -p "$FAILED_DIR"

# Find the most recent slurm output file : This only works if the .out file related to this restart job gets re-directed to another directory and not slurmlogs
# Otherwise, the most recent slurm output file will be the one belongs to this job
# Therefore, we recommend manually entering the jobID ralted to FAILED_JOB_ID variable
FAILED_JOB_ID="Enter the timedout/failed jobID" 
LATEST_LOG=$(ls -t slurmlogs/${FAILED_JOB_ID}.out | head -n 1)

# Extract successfully processed files from the log
PROCESSED_FILES=$(grep "Successfully processed" "$LATEST_LOG" | awk '{print $NF}')

# Function to check if a file has been processed
file_processed() {
    local file="$1"
    echo "$PROCESSED_FILES" | grep -q "$file"
}

# Function to process a file
process_file() {
    local file="$1"
    if ${APPTAINER_CMD} Models --cpu-count ${SLURM_CPUS_PER_TASK} --apply "$file"; then
        echo "Successfully processed $file"
        return 0
    else
        echo "Failed to process $file"
        return 1
    fi
}

consecutive_failures=0
max_consecutive_failures=10

# Process unprocessed .txt files
for file in "$WORK_DIR"/*.txt "$FAILED_DIR"/*.txt; do
    if [ -f "$file" ] && [ "$(basename "$file")" != "ExampleConfig.txt" ]; then
        if ! file_processed "$(basename "$file")"; then
            if process_file "$file"; then
                consecutive_failures=0
                # If the file was in FAILED directory, move it back to WORK_DIR
                if [[ "$file" == "$FAILED_DIR"/* ]]; then
                    mv "$file" "$WORK_DIR/"
                fi
            else
                mv "$file" "$FAILED_DIR/"
                ((consecutive_failures++))
                
                if [ $consecutive_failures -ge $max_consecutive_failures ]; then
                    echo "Error: $max_consecutive_failures consecutive failures reached. Terminating job." >&2
                    exit 1
                fi
            fi
        fi
    fi
done
