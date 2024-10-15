#!/bin/bash 

# Verify the built version
BUILT_VERSION=$(apptainer exec ${IMAGE_PATH}/apsim-${APSIM_VERSION}.aimg Models | grep APSIM | awk -F'[ ©]' '{print $2}')

if [ "$BUILT_VERSION" == "$APSIM_VERSION" ]; then
    echo "Version verification successful: $BUILT_VERSION"
else
    echo "Version verification failed: expected $APSIM_VERSION, got $BUILT_VERSION"
    exit 1
fi