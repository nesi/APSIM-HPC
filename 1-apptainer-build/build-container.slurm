#!/bin/bash -e

#SBATCH --job-name	apsim-container-build
#SBATCH --time          0-01:30:00                #DD-HH:MM:SS
#SBATCH --mem		24GB      
#SBATCH --cpus-per-task	4
#SBATCH --output 	%j.out

#define the version of APSIM on following variable
export APSIM_VERSION=""

#define paths for definition file, where the image should be stored
export IMAGE_PATH="../../apsim-simulations/container/"

if [ ! -d "${IMAGE_PATH}" ]; then
mkdir -p ${IMAGE_PATH}
fi

#purge any pre-loaded modules and load Apptainer
module purge
module load Apptainer/1.2.5

export CACHETMPDIR="/agr/persist/projects/2024_apsim_improvements/container-cache"

if [ ! -d "${CACHETMPDIR}"  ]; then
mkdir -p ${CACHETMPDIR}
fi 

export TMPDIR=${CACHETMPDIR}
mkdir -p $TMPDIR
export TMPDIR


#set cache and tmpdir to nobackup. Otherwise, /home will be used by default which is not ideal due to it's 20GB strict quota
export APPTAINER_CACHEDIR=${CACHETMPDIR}
export APPTAINER_TMPDIR=${CACHETMPDIR}

#following directive (setfacl) is a unique requirement to nobackup (GPFS) filesystem
setfacl -b "$APPTAINER_TMPDIR"

#Can not execute build command while the APPTAINER_BIND variable is invoked. 
unset APPTAINER_BIND


apptainer build --warn-unused-build-args --force --fakeroot ${IMAGE_PATH}/apsim-${APSIM_VERSION}.aimg Apptainer.def


# Verify the built version
BUILT_VERSION=$(apptainer exec ${IMAGE_PATH}/apsim-${APSIM_VERSION}.aimg Models | grep APSIM | awk -F'[ ©]' '{print $2}')

if [ "$BUILT_VERSION" == "$APSIM_VERSION" ]; then
    echo "Version verification successful: $BUILT_VERSION"
else
    echo "Version verification failed: expected $APSIM_VERSION, got $BUILT_VERSION"
    exit 1
fi

#run the cleanup script at the end
./clean.sh
