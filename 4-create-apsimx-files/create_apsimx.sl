#!/bin/bash -e

#SBATCH --job-name=apsim_models
#SBATCH --output=slurmlogs/%j.out
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:45:00

module load Apptainer
export APPTAINER_BIND="/agr/scratch,/agr/persist"
export APPTAINER_CMD="apptainer exec /agr/persist/projects/2024_apsim_improvements/apsim-simulations/container/apsim-2024.09.7579.0.aimg"


# Run command for all .txt files, excluding ExampleConfig.txt
for file in *.txt; do
    if [ -f "$file" ] && [ "$file" != "ExampleConfig.txt" ]; then
        ${APPTAINER_CMD} Models --cpu-count ${SLURM_CPUS_PER_TASK} --apply "$file"
    fi
done
