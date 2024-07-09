#!/bin/bash -e 

#SBATCH --account       2024_apsim_improvements
#SBATCH --job-name      apsim-test
#SBATCH --cpus-per-task 4
#SBATCH --mem           4G
#SBATCH --time          00:30:00
#SBATCH --output        slog/%j.out

#purge any pre-loaded modules and load just Apptainer
module purge >/dev/null 2>&1
module load Apptainer

#define which version of the container image to be used
export VERSION="2024.05.7470.0"

#Define variable to container path
export APPTAINER_IMAGE="/APSIM-${VERSION}.aimg"

#Define apptainer exec comamand 
export CMD="apptainer exec ${APPTAINER_IMAGE}"

#execute the function of interest
${CMD} Models --apply ${PWD}/ExampleConfig.txt
