# APSIM-HPC New Workflow (Batch Mode)

## Overview

This workflow uses APSIM's `--apply` and `--batch` CLI flags (introduced in APSIM Next Gen)
to replace the old multi-step per-file approach. Instead of generating one `.apsimx` file
per soil×weather combination, we use:

1. **One command template** (`command_template.txt`) with `$placeholder` variables
2. **Batch CSV files** where each row defines a set of variable substitutions
3. APSIM iterates through all rows internally — one `.db` output per batch

```
Models --apply command_template.txt --batch batch_0001.csv --cpu-count 16
```

Each CSV row loads a copy of the base `.apsimx` template, swaps the soil, weather file,
and experiment name, then runs all simulations. Results accumulate in a single `.db` file
per batch.

## Architecture

```
new-workflow/
├── README.md                  # This file
├── config.yaml                # Central configuration (paths, SLURM settings, batch size)
├── command_template.txt       # APSIM command template with $placeholders
├── generate_batches.py        # Generate batch CSVs from combinations CSV
├── Snakefile                  # Snakemake workflow (run_batch → validate → merge)
├── submit_workflow.slurm      # SLURM controller job (submits Snakemake unattended)
├── run_workflow.sh            # Interactive alternative to submit_workflow.slurm
├── .gitattributes             # Enforce LF line endings for git
└── scripts/
    └── validate_results.py    # Standalone validation script
```

## Prerequisites

- **APSIM Next Gen** r8012+ in an Apptainer container
- **Snakemake** 7.32.3+ (loaded via `module load snakemake`)
- **Python** 3.11+ with `pyyaml` (typically included with Snakemake module)
- A **combinations CSV** (e.g. `AgentInfo.csv`) with columns for weather file names and soil names

## Workflow Steps

### 1. Configure (`config.yaml`)

Set paths to your `.apsimx` template, soil library, container image, and SLURM resources:

```yaml
apsimx_template: "r8012_SoETemplate.apsimx"
soil_library: "2026-03-10_SoilLibrary_r8012.apsimx"
combinations_csv: "AgentInfo.csv"
rows_per_batch: 1000
container_image: "/path/to/apsim-2026.03.8012.0.aimg"
apptainer_bind: "/agr/scratch,/agr/persist"

slurm:
  time: "24:00:00"
  cpus_per_task: 16
  mem: "32G"
  account: "2024_apsim_improvements"
```

### 2. Generate Batch CSVs (`generate_batches.py`)

```bash
python generate_batches.py --config config.yaml
```

Reads the combinations CSV, validates that all soil names exist in the soil library,
then splits the factorial design into batch CSV files (default: 5000 rows each) under `batches/`.

Each batch CSV has columns: `batch-name`, `soil-name`, `weather-file`, `sim-name`.

### 3. Command Template (`command_template.txt`)

The template uses `$placeholder` variables that APSIM substitutes per CSV row:

```
load $batch-name.apsimx
[Weather].FileName = $weather-file.met
replace [Soil] with $soil-name from 2026-03-10_SoilLibrary_r8012.apsimx
[Experiment].Name = $sim-name
run
```

The Snakefile copies the template `.apsimx` → `batch_XXXX.apsimx` so each batch
writes its results to `batch_XXXX.db`.

### 4. Run the Workflow

**Option A: Unattended via SLURM controller (recommended)**

```bash
mkdir -p slurmlogs
sbatch submit_workflow.slurm
```

This submits a lightweight controller job that runs Snakemake, which in turn submits
one SLURM child job per batch CSV via `--cluster sbatch`.

Monitor progress:
```bash
squeue -u $USER
tail -f slurmlogs/snakemake_controller_*.out
```

**Option B: Interactive**

```bash
bash run_workflow.sh
```

### 5. Outputs

After completion, the `OutputDatabases/` directory contains:

- `batch_XXXX.db` — One SQLite database per batch with all simulation results
- `validation_report.csv` — Per-simulation status (COMPLETED/MISSING) with simulation counts
- `validation_summary.txt` — Summary of expected vs. completed simulations

### 6. Optional: Merge Databases

To merge all batch `.db` files into a single database:

```bash
snakemake merge_databases --cores 1
```

## Snakemake Rules

| Rule | Purpose |
|------|---------|
| `run_batch` | Run one batch CSV through APSIM (1 SLURM job per batch) |
| `validate_results` | Query all `.db` files and compare against expected simulations |
| `merge_databases` | Merge all batch `.db` files into one (manual/optional) |
| `list_simulations` | Dry-run: list all simulation names that would be generated |
| `clean` | Remove all generated outputs |

## Resource Allocation Guide

There are **three layers** of SLURM jobs in this workflow, each with separate resource
allocations. Understanding which settings control which process is critical for tuning.

### Layer 1: Controller Job (`submit_workflow.slurm`)

**What it does:** Runs Snakemake itself, which coordinates everything. It does NOT run
APSIM — it only submits and monitors child jobs.

**Where configured:** Hardcoded `#SBATCH` directives at the top of `submit_workflow.slurm`:

```
#SBATCH --time=3-00:00:00      # Wall time for the entire workflow (3 days)
#SBATCH --cpus-per-task=2      # Snakemake + Python overhead only
#SBATCH --mem=4G               # Snakemake + Python overhead only
#SBATCH --account=2024_apsim_improvements
```

**Tuning notes:**
- `--time` must be long enough for ALL batches to complete (including queue wait time).
  If this job times out, Snakemake stops submitting/tracking child jobs.
- `--cpus-per-task=2` and `--mem=4G` are minimal — Snakemake itself uses very little.
- `MAX_SLURM_JOBS` (default: 20) controls how many batch jobs run in parallel.
  Set via environment variable before submission: `MAX_SLURM_JOBS=50 sbatch submit_workflow.slurm`

### Layer 2: Batch Jobs — `run_batch` rule (Snakefile)

**What it does:** Each batch CSV gets its own SLURM job. This is where APSIM actually
runs — the heavy compute work. One job processes all rows in one batch CSV.

**Where configured:** The `slurm:` section of `config.yaml`:

```yaml
slurm:
  time: "24:00:00"       # Wall time PER BATCH job
  cpus_per_task: 16      # CPUs for APSIM (passed to --cpu-count)
  mem: "32G"             # Memory PER BATCH job
```

**How it flows:**
1. `config.yaml` → read by Snakefile into the `resources:` block of `run_batch`
2. Snakefile `resources:` → injected into the `sbatch` command via `{resources.time}`,
   `{resources.mem_mb}`, `{resources.cpus_per_task}` placeholders
3. The `sbatch` command template in `submit_workflow.slurm`:
   ```
   sbatch --chdir=${WORKDIR} \
          --time={resources.time} \          ← from config.yaml slurm.time
          --mem={resources.mem_mb}M \        ← from config.yaml slurm.mem (converted to MB)
          --cpus-per-task={resources.cpus_per_task}  ← from config.yaml slurm.cpus_per_task
   ```
4. Inside the job, `--cpu-count {params.cpus}` tells APSIM how many threads to use
   (also from `config.yaml` `slurm.cpus_per_task`)

**Tuning notes:**
- `cpus_per_task` directly controls APSIM parallelism — more CPUs = faster per batch.
- `time` depends on `rows_per_batch`: more rows per batch = longer runtime.
- `mem` depends on the model complexity. 32G is generous for most APSIM models.
- With `rows_per_batch: 1000` and `cpus_per_task: 16`, expect each batch to take
  several hours depending on model complexity.

### Layer 3: Lightweight Jobs — `validate_results` and `merge_databases` rules

These run after all batch jobs complete and need minimal resources.

**`validate_results`** — Reads batch CSVs and queries `.db` files with SQLite:
```
resources:
  time: "00:10:00"       # 10 minutes
  mem_mb: 4000           # 4 GB
  cpus_per_task: 1       # Single-threaded
```

**`merge_databases`** (optional, manual) — Merges all `.db` files into one:
```
resources:
  time: "01:00:00"       # 1 hour
  mem_mb: 8000           # 8 GB
  cpus_per_task: 1       # Single-threaded
```

These are hardcoded in the Snakefile since they don't need tuning.

### Summary Diagram

```
sbatch submit_workflow.slurm
│
│  Controller Job (Layer 1)
│  3 days, 2 CPUs, 4G RAM
│  Runs: Snakemake
│
├──→ sbatch run_batch (batch_0001)     ← Layer 2
│    24h, 16 CPUs, 32G RAM               (from config.yaml)
│    Runs: APSIM --cpu-count 16
│
├──→ sbatch run_batch (batch_0002)     ← Layer 2
│    24h, 16 CPUs, 32G RAM
│    Runs: APSIM --cpu-count 16
│
├──→ ... (up to MAX_SLURM_JOBS in parallel)
│
├──→ sbatch validate_results           ← Layer 3
│    10min, 1 CPU, 4G RAM
│    Runs: Python/SQLite queries
│
└──→ Done
```

### Quick Reference: What to Change Where

| Want to change... | Edit this |
|-------------------|-----------|
| Total workflow wall time | `submit_workflow.slurm` line `#SBATCH --time=` |
| Max parallel batch jobs | `MAX_SLURM_JOBS` env var (default: 20) |
| Time per APSIM batch job | `config.yaml` → `slurm.time` |
| CPUs per APSIM batch job | `config.yaml` → `slurm.cpus_per_task` |
| Memory per APSIM batch job | `config.yaml` → `slurm.mem` |
| Rows per batch (affects job count vs. duration) | `config.yaml` → `rows_per_batch` |
| SLURM account/project | `config.yaml` → `slurm.account` AND `submit_workflow.slurm` `#SBATCH --account=` |
| Validation/merge resources | Snakefile → `resources:` block in respective rule |

## Key Improvements Over Old Workflow

| Aspect | Old Workflow (8 steps) | New Workflow |
|--------|------------------------|-------------|
| Files generated | 1 `.txt` + 1 `.apsimx` per combo | 1 template + N batch CSVs |
| SLURM jobs | 1 per `.apsimx` file (thousands) | 1 per batch CSV (tens) |
| Complexity | 8+ scripts across Bash/R/Python | 1 Python script + 1 Snakefile |
| APSIM invocations | 2 per combo (create + run) | 1 per batch |
| Result validation | Manual / separate scripts | Built into Snakemake pipeline |

## Troubleshooting

### DOS Line Endings (CRLF)

Files edited on Windows get `\r\n` line endings which cause issues on Linux:
- SLURM rejects scripts: `sbatch: error: Batch script contains DOS line breaks`
- APSIM silently produces empty `.db` files when CSV inputs have CRLF

**Fix:** After syncing files from Windows to HPC, run:
```bash
sed -i 's/\r$//' submit_workflow.slurm run_workflow.sh Snakefile command_template.txt generate_batches.py config.yaml scripts/validate_results.py
```

The Snakefile also strips CRLF from batch CSVs and the command template automatically
at runtime via `sed`.

### Empty `.db` Files

If APSIM produces a 0-byte `.db` despite exiting with code 0, check:
1. **Line endings** — run the `sed` command above
2. **Working directory** — the `sbatch` command must include `--chdir` pointing to
   the project directory (already configured in `submit_workflow.slurm`)
3. **Container path mismatch** — on compute nodes, the real path is `/mnt/gpfs/scratch/...`
   but the container only has `/agr/scratch` via bind mounts. The Snakefile handles
   this with `--pwd` and automatic path translation.
4. **File paths** — ensure the `.apsimx` template, soil library, and `.met` files
   are accessible from the compute nodes (check `apptainer_bind` in `config.yaml`)

### Snakemake Lock Error

```
LockException: Error: Directory cannot be locked.
```

This happens when a previous Snakemake run was killed (timeout, cancel, power loss)
before it could release its lock.

**Fix:**
```bash
module load snakemake/7.32.3-foss-2023a-Python-3.11.6
snakemake --unlock
sbatch submit_workflow.slurm
```

### Batch Jobs Timed Out

If batch jobs are killed by SLURM due to exceeding their wall time:

1. **Check which batches completed** — any non-empty `.db` in `OutputDatabases/`:
   ```bash
   for db in OutputDatabases/batch_*.db; do
       [ -s "$db" ] && echo "OK:   $db ($(du -h "$db" | cut -f1))" || echo "FAIL: $db (empty)"
   done
   ```

2. **Check how many simulations completed per batch:**
   ```bash
   for db in OutputDatabases/batch_*.db; do
       [ -s "$db" ] && echo "$db: $(sqlite3 "$db" "SELECT COUNT(DISTINCT Name) FROM _Simulations") sims"
   done
   ```

3. **Increase time and/or reduce batch size** in `config.yaml`:
   ```yaml
   rows_per_batch: 1000   # Fewer rows = shorter jobs (default was 5000)
   slurm:
     time: "24:00:00"     # More wall time per batch job
   ```
   Also increase controller time in `submit_workflow.slurm`:
   ```
   #SBATCH --time=3-00:00:00   # 3 days for the controller
   ```

4. **Clean stale outputs and re-run:**
   ```bash
   rm -f batch_*.db batch_*.apsimx batch_*_command.txt
   rm -f batches/*.done batches/*.csv batches/batch_manifest.txt
   rm -rf OutputDatabases/
   snakemake --unlock   # if needed
   sbatch submit_workflow.slurm
   ```

   **Note:** Timed-out jobs leave `.db` files in `./` (project root) instead of
   `./OutputDatabases/` because the `mv` step never ran. Always clean both locations.

### Resuming a Partially Completed Run

Snakemake automatically skips batches that already have completed outputs. To resume:

1. **Keep completed outputs, remove failed ones:**
   ```bash
   # Remove empty (failed) .db files from OutputDatabases
   find OutputDatabases -name "batch_*.db" -size 0 -delete
   # Remove .done markers for batches that don't have a valid .db
   for done_file in batches/*.done; do
       batch_id=$(basename "$done_file" .done)
       db_file="OutputDatabases/${batch_id}.db"
       [ ! -s "$db_file" ] && rm -f "$done_file"
   done
   # Remove leftover files from failed jobs in project root
   rm -f batch_*.db batch_*.apsimx batch_*_command.txt
   # Remove stale validation output
   rm -f OutputDatabases/validation_*
   ```

2. **Unlock if necessary and re-submit:**
   ```bash
   snakemake --unlock 2>/dev/null
   sbatch submit_workflow.slurm
   ```
   Snakemake will only re-run batches with missing or empty `.db` files.

### Checking Progress While Running

```bash
# See all your SLURM jobs
squeue --me

# Count how many batches have completed (non-empty .db)
ls -la OutputDatabases/batch_*.db 2>/dev/null | awk '$5 > 0' | wc -l

# Watch the controller log
tail -f slurmlogs/snakemake_controller_*.out

# Check a specific batch log
cat slurmlogs/batch_0001.log

# Check simulation counts in completed databases
for db in OutputDatabases/batch_*.db; do
    [ -s "$db" ] && echo "$db: $(sqlite3 "$db" "SELECT COUNT(DISTINCT Name) FROM _Simulations") sims"
done
```

### Starting Completely Fresh

To wipe everything and start over:
```bash
# Cancel any running jobs
scancel -u $USER

# Remove all generated files
rm -f batch_*.db batch_*.apsimx batch_*_command.txt
rm -f batches/*.done batches/*.csv batches/batch_manifest.txt
rm -rf OutputDatabases/
rm -f slurmlogs/*.log slurmlogs/*.out slurmlogs/*.err
rm -rf .snakemake/

# Fix line endings after syncing from Windows
sed -i 's/\r$//' submit_workflow.slurm run_workflow.sh Snakefile \
    command_template.txt generate_batches.py config.yaml scripts/validate_results.py

# Re-submit
sbatch submit_workflow.slurm
```

### Common Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `Batch script contains DOS line breaks` | Windows CRLF line endings | `sed -i 's/\r$//' submit_workflow.slurm` |
| `Directory cannot be locked` | Stale Snakemake lock from killed run | `snakemake --unlock` |
| `.db` is 0 bytes | APSIM couldn't find files (wrong CWD) | Check `--pwd` and bind mounts |
| `FATAL: failed to set working directory` | Container path mismatch | Path translation in Snakefile (`/mnt/gpfs/scratch` → `/agr/scratch`) |
| `FileNotFoundException: command_template.txt` | Container CWD fell back to `$HOME` | Ensure `--pwd` with translated path |
| Batch job `TIMEOUT` | `rows_per_batch` too large or `slurm.time` too short | Reduce `rows_per_batch` or increase `slurm.time` in `config.yaml` |
| Controller job dies, child jobs orphaned | Controller `--time` too short | Increase `#SBATCH --time` in `submit_workflow.slurm` |
| `WARNING: Soil 'X' not found in library` | Soil name in CSV doesn't match soil library | Check soil names; those combos are skipped |
