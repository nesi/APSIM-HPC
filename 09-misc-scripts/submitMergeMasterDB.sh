#!/bin/bash -e
#SBATCH --job-name=Merge-DB-Files
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4GB

python3 MergeMasterDBFiles.py
