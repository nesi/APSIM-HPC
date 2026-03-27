#!/bin/bash
# ============================================================
# APSIM-HPC New Workflow - Run Script
# ============================================================
# This script orchestrates the complete new workflow:
#   1. Generate batch CSV files from soil/weather factorial design
#   2. Run all batches via Snakemake + SLURM
#   3. Sort and validate results
# ============================================================

set -euo pipefail

# Color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${GREEN}${BOLD}============================================${NC}"
echo -e "${GREEN}${BOLD}  APSIM-HPC Batch Workflow (New)${NC}"
echo -e "${GREEN}${BOLD}============================================${NC}"
echo ""

# --- Configuration ---
MAX_SLURM_JOBS=${MAX_SLURM_JOBS:-20}      # Max parallel SLURM jobs
SNAKEMAKE_PROFILE=${SNAKEMAKE_PROFILE:-""} # Set to "slurm" to use ~/.config/snakemake/slurm
USE_CLUSTER_CMD=${USE_CLUSTER_CMD:-true}   # Use --cluster sbatch if no profile

# --- Detect cluster environment ---
echo -e "${YELLOW}[1/4] Detecting cluster environment...${NC}"
if [[ $(hostname) == *eri* ]]; then
    echo "  Detected: eRI cluster"
    module purge && module load snakemake/7.32.3-foss-2023a-Python-3.11.6
elif [[ $(hostname) == *mahuika* ]]; then
    echo "  Detected: Mahuika cluster"
    module purge >/dev/null 2>&1 && module load snakemake/7.32.3-gimkl-2022a-Python-3.11.3
else
    echo "  No known cluster detected - using local Snakemake"
fi
echo ""

# --- Generate batch CSVs ---
echo -e "${YELLOW}[2/4] Generating batch CSV files...${NC}"
python generate_batches.py --config config.yaml
echo ""

# --- Create log directory ---
mkdir -p slurmlogs

# --- Run Snakemake ---
echo -e "${YELLOW}[3/4] Running Snakemake workflow...${NC}"
echo "  Max parallel jobs: ${MAX_SLURM_JOBS}"

SNAKEMAKE_CMD="snakemake --rerun-incomplete --jobs ${MAX_SLURM_JOBS}"

if [ -n "${SNAKEMAKE_PROFILE}" ]; then
    echo "  Using Snakemake profile: ${SNAKEMAKE_PROFILE}"
    SNAKEMAKE_CMD="${SNAKEMAKE_CMD} --profile ${SNAKEMAKE_PROFILE}"
elif [ "${USE_CLUSTER_CMD}" = true ]; then
    echo "  Using direct --cluster sbatch submission"

    # Build optional SLURM flags from config
    PARTITION=$(python -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('slurm',{}).get('partition',''))")
    ACCOUNT=$(python -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('slurm',{}).get('account',''))")
    EXTRA_SBATCH=""
    [ -n "${PARTITION}" ] && EXTRA_SBATCH="${EXTRA_SBATCH} --partition=${PARTITION}"
    [ -n "${ACCOUNT}" ] && EXTRA_SBATCH="${EXTRA_SBATCH} --account=${ACCOUNT}"

    WORKDIR=$(pwd)
    SNAKEMAKE_CMD="${SNAKEMAKE_CMD} --cluster 'sbatch \
        --chdir=${WORKDIR} \
        --time={resources.time} \
        --mem={resources.mem_mb}M \
        --cpus-per-task={resources.cpus_per_task}${EXTRA_SBATCH} \
        --output=slurmlogs/%j.out \
        --error=slurmlogs/%j.err'"
else
    echo "  Running locally (no cluster submission)"
    SNAKEMAKE_CMD="snakemake --cores ${MAX_SLURM_JOBS} --rerun-incomplete"
fi

echo ""
echo -e "${YELLOW}  Command: ${SNAKEMAKE_CMD}${NC}"
echo ""

eval ${SNAKEMAKE_CMD}

# --- Summary ---
echo ""
echo -e "${GREEN}${BOLD}============================================${NC}"
echo -e "${GREEN}${BOLD}[4/4] Workflow complete!${NC}"
echo -e "${GREEN}${BOLD}============================================${NC}"

# Print results summary if available
DB_OUTPUT_DIR=$(python -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c.get('db_output_dir', 'OutputDatabases'))")
if [ -f "${DB_OUTPUT_DIR}/validation_summary.txt" ]; then
    echo ""
    cat "${DB_OUTPUT_DIR}/validation_summary.txt"
fi

echo ""
echo "Results location:"
echo "  PASSED: ${DB_OUTPUT_DIR}/PASSED/"
echo "  FAILED: ${DB_OUTPUT_DIR}/FAILED/"
echo ""
