#!/bin/bash -e

#SBATCH --job-name=apsim_snake
#SBATCH --output=slurmlogs/snakemake_%j.out
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Load necessary modules
module load snakemake
module load Apptainer

# Create output directories
mkdir -p OutputDatabases

# Run Snakemake
snakemake --cores 4 --jobs 10 \
    --cluster "sbatch --cpus-per-task=4 --mem=8G --time=02:00:00 --output=slurmlogs/slurm_%j.out --error=slurmlogs/slurm_%j.err"
