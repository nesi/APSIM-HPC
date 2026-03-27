#!/bin/bash -l
#SBATCH -J Compare_Agent
# SBATCH -A landcare03392  # <- REPLACE this with your "Project Code"
#SBATCH --time=3:00:00   # Walltime (HH:MM:SS)
#SBATCH --cpus-per-task=2  # Number of logical CPUs
#SBATCH --mem=32GB         # Memory in GB
#SBATCH --output=pp_out.txt
#SBATCH --error=pp_err.txt
#SBATCH --mail-type=ALL
#SBATCH --mail-user=jing.guo@agresearch.co.nz

ml Python/3.11.6-foss-2023a
python compare_agent_data.py