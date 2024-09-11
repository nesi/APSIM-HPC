#!/bin/bash -e

#SBATCH --job-name=apsim_models
#SBATCH --output=slurmlogs/%A_%a.out
#SBATCH --array=1-10    #This will run  10 array tasks. If you want to control how many tasks should be "RUNNING" at any given time, use Slurm throttle with % .i.e. 1-10%5 will run 5
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00

# Load necessary modules
#module use /agr/persist/projects/2024_apsim_improvements/APSIM-eri-mahuika/2-apsim-module/APSIM/
#module load APSIM

module load Apptainer
export APPTAINER_BIND="/agr/scratch,/agr/persist"

export APPTAINER_CMD="apptainer exec /agr/persist/projects/2024_apsim_improvements/apsim-simulations/container/apsim-2024.08.7572.0.aimg"



# Directory containing config files
CONFIG_DIR="./ConfigFiles"

# Directory for output database files
OUTPUT_DIR="OutputDatabases"

# Create output directories if they don't exist
mkdir -p $OUTPUT_DIR

# Get list of config files
CONFIG_FILES=($(ls $CONFIG_DIR/*.txt))

# Get the config file for this job array task
CONFIG_FILE=${CONFIG_FILES[$SLURM_ARRAY_TASK_ID - 1]}

# Extract the base name of the config file (without extension)
BASE_NAME=$(basename $CONFIG_FILE .txt)

# Run APSIM Models command
${APPTAINER_CMD} Models --apply $CONFIG_FILE

# Move the output database to the output directory
mv ${BASE_NAME}.db $OUTPUT_DIR/

# Append the database filename to a list file
echo "${BASE_NAME}.db" >> $OUTPUT_DIR/database_list.txt

echo "Completed processing $CONFIG_FILE"
