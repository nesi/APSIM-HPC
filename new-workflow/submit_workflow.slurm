#!/bin/bash
#SBATCH --job-name=apsim-snakemake
#SBATCH --time=3-00:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --account=2024_apsim_improvements
#SBATCH --output=slurmlogs/snakemake_controller_%j.out
#SBATCH --error=slurmlogs/snakemake_controller_%j.err
# ============================================================
# APSIM-HPC Workflow - SLURM Controller Job
# ============================================================
# This submits Snakemake as a SLURM job so it can run unattended.
# Snakemake then submits each batch as a child SLURM job.
#
# Usage:
#   mkdir -p slurmlogs
#   sbatch submit_workflow.slurm
#
# Monitor:
#   squeue -u $USER
#   tail -f slurmlogs/snakemake_controller_*.out
# ============================================================

set -euo pipefail

echo "Snakemake controller started: $(date)"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node:   $(hostname)"
echo ""

# --- Load modules ---
if [[ $(hostname) == *eri* ]]; then
    module purge && module load snakemake/7.32.3-foss-2023a-Python-3.11.6
elif [[ $(hostname) == *mahuika* ]]; then
    module purge >/dev/null 2>&1 && module load snakemake/7.32.3-gimkl-2022a-Python-3.11.3
fi

# --- Configuration ---
MAX_SLURM_JOBS=${MAX_SLURM_JOBS:-20}

# --- Generate batch CSVs ---
echo "[1/3] Generating batch CSV files..."
python generate_batches.py --config config.yaml
echo ""

# --- Build SLURM flags from config ---
PARTITION=$(python -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('slurm',{}).get('partition',''))")
ACCOUNT=$(python -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('slurm',{}).get('account',''))")
EXTRA_SBATCH=""
[ -n "${PARTITION}" ] && EXTRA_SBATCH="${EXTRA_SBATCH} --partition=${PARTITION}"
[ -n "${ACCOUNT}" ] && EXTRA_SBATCH="${EXTRA_SBATCH} --account=${ACCOUNT}"

# --- Run Snakemake ---
echo "[2/3] Running Snakemake (submitting child SLURM jobs)..."
echo "  Max parallel jobs: ${MAX_SLURM_JOBS}"
echo ""

WORKDIR=$(pwd)
snakemake --rerun-incomplete --jobs ${MAX_SLURM_JOBS} \
    --cluster "sbatch \
        --chdir=${WORKDIR} \
        --time={resources.time} \
        --mem={resources.mem_mb}M \
        --cpus-per-task={resources.cpus_per_task}${EXTRA_SBATCH} \
        --output=slurmlogs/%j.out \
        --error=slurmlogs/%j.err"

# --- Summary ---
echo ""
echo "[3/3] Workflow complete: $(date)"

DB_OUTPUT_DIR=$(python -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('db_output_dir', 'OutputDatabases'))")
if [ -f "${DB_OUTPUT_DIR}/validation_summary.txt" ]; then
    echo ""
    cat "${DB_OUTPUT_DIR}/validation_summary.txt"
fi
