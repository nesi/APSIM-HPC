#!/bin/bash

# Name of the Apptainer definition file
DEF_FILE="Apptainer.def"
SLURM_FILE="build-container.slurm"

# Check if the files exist
if [ ! -f "$DEF_FILE" ]; then
    echo "Error: $DEF_FILE not found."
    exit 1
fi

if [ ! -f "$SLURM_FILE" ]; then
    echo "Error: $SLURM_FILE not found."
    exit 1
fi

# Remove the specific line under %setup in Apptainer.def
sed -i '/%setup/,/^%/{/^\s*curl --silent -o ${APPTAINER_ROOTFS}\/ApsimSetup\.deb/d;}' "$DEF_FILE"

# Clear the values for TAG and YEAR.MONTH under %arguments in Apptainer.def
sed -i '/%arguments/,/^%/{
    s/^\s*TAG=.*/    TAG=/;
    s/^\s*YEAR\.MONTH=.*/    YEAR.MONTH=/;
}' "$DEF_FILE"

# Clear the value for APSIM_VERSION in build-container.slurm
sed -i 's/^export APSIM_VERSION=".*"/export APSIM_VERSION=""/' "$SLURM_FILE"

# Check if the operations were successful
if [ $? -eq 0 ]; then
    echo "Successfully cleaned up $DEF_FILE and $SLURM_FILE"
else
    echo "Error: Failed to clean up files"
    exit 1
fi

# Display the updated sections
echo "Updated %setup section in $DEF_FILE:"
sed -n '/%setup/,/^%/p' "$DEF_FILE"

echo "Updated %arguments section in $DEF_FILE:"
sed -n '/%arguments/,/^%/p' "$DEF_FILE"

echo "Updated APSIM_VERSION in $SLURM_FILE:"
grep "export APSIM_VERSION" "$SLURM_FILE"
