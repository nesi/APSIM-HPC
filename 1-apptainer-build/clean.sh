#!/bin/bash

# Name of the Apptainer definition file
DEF_FILE="Apptainer.def"

# Check if the file exists
if [ ! -f "$DEF_FILE" ]; then
    echo "Error: $DEF_FILE not found."
    exit 1
fi

# Use sed to remove the specific line under %setup
sed -i '/%setup/,/^%/{/^\s*curl --silent -o ${APPTAINER_ROOTFS}\/ApsimSetup\.deb/d;}' "$DEF_FILE"

# Check if the operation was successful
if [ $? -eq 0 ]; then
    echo "Successfully removed the specified line from $DEF_FILE"
else
    echo "Error: Failed to remove the line from $DEF_FILE"
    exit 1
fi

# Optionally, display the updated %setup section
echo "Updated %setup section:"
sed -n '/%setup/,/^%/p' "$DEF_FILE"
