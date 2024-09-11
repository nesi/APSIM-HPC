#!/bin/bash -e

#SBATCH --job-name=apsim_models
#SBATCH --output=slurmlogs/%A_%a.out
#SBATCH --cpus-per-task=12
#SBATCH --mem=8G
#SBATCH --time=00:10:00

#Load apptainer module and mount the filesystem
module load Apptainer
export APPTAINER_BIND="/agr/scratch,/agr/persist"

export APPTAINER_CMD="apptainer exec /agr/persist/projects/2024_apsim_improvements/apsim-simulations/container/apsim-2024.09.7579.0.aimg"

# Get the list of .apsimx files, excluding specified files
mapfile -t apsimx_files < <(find . -maxdepth 1 -name "*.apsimx" ! -name "2023-10-09_MasterSoilApsimLibrary.apsimx" ! -name "LargerExample.apsimx" | sort)

# Check if the array is empty
if [ ${#apsimx_files[@]} -eq 0 ]; then
    echo "No eligible .apsimx files found. Exiting."
    exit 1
fi

# Get the file for this job array task
file_index=$((SLURM_ARRAY_TASK_ID - 1))
current_file="${apsimx_files[$file_index]}"

# Extract the filename without extension
filename=$(basename "$current_file" .apsimx)

# Check if the corresponding .db file exists
if [ ! -f "${filename}.db" ]; then
    echo "Error: ${filename}.db does not exist."
    exit 1
fi

# Run the command
echo "Processing $current_file"
$APPTAINER_CMD Models "$current_file"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Successfully processed $current_file"
else
    echo "Error processing $current_file"
    exit 1
fi

