#!/bin/bash -e

#SBATCH --job-name	apsim-container-build
#SBATCH --time          0-01:30:00                #DD-HH:MM:SS
#SBATCH --mem		24GB      
#SBATCH --cpus-per-task	4
#SBATCH --output 	slog/%j.out

#define the version of APSIM on following variable
export APSIM_VERSION="2024.07.7558.0"

#define paths for definition file, where the image should be stored
export IMAGE_PATH="../apsim-simulations/container/"

#purge any pre-loaded modules and load Apptainer
module purge
module load Apptainer/1.2.5

#set cache and tmpdir to nobackup. Otherwise, /home will be used by default which is not ideal due to it's 20GB strict quota
export APPTAINER_CACHEDIR="../../container-cache/"
export APPTAINER_TMPDIR="../../container-cache/"

#following directive (setfacl) is a unique requirement to nobackup (GPFS) filesystem
setfacl -b "$APPTAINER_TMPDIR"

#Can not execute build command while the APPTAINER_BIND variable is invoked. 
unset APPTAINER_BIND


apptainer build --force --fakeroot ${IMAGE_PATH}/APSIM-${APSIM_VERSION}.aimg ${DEF_FILE_PATH}/Apptainer.${APSIM_VERSION}
