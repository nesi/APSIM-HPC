#!/bin/bash

#SBATCH --job-name=apsim_models
#SBATCH --output=slurmlogs/%j.out
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=16:00:00

module load Apptainer
export APPTAINER_BIND="/agr/scratch,/agr/persist"
export APPTAINER_CMD="apptainer exec /agr/persist/projects/2024_apsim_improvements/apsim-simulations/container/apsim-2024.09.7579.0.aimg"

# Create FAILED directory if it doesn't exist
mkdir -p FAILED

#Purpose of this counter is to allow ten consecutive failures without killing the for loop
#Reason for failures were as mentioned in this gh issue https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/35
#Expected number of consecutive failures per sample is equivalent to number of .met weather files
#Therefore, we recommend `max_consecutive_failures` = [ number of weather files + 1 ]
consecutive_failures=0
max_consecutive_failures=10

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

# Run command for all .txt files, excluding ExampleConfig.txt
for file in *.txt; do
    if [ -f "$file" ] && [ "$file" != "ExampleConfig.txt" ]; then
        if process_file "$file"; then
            consecutive_failures=0
        else
            mv "$file" FAILED/
            ((consecutive_failures++))
            
            if [ $consecutive_failures -ge $max_consecutive_failures ]; then
                echo "Error: $max_consecutive_failures consecutive failures reached. Terminating job." >&2
                exit 1
            fi
        fi
    fi
done