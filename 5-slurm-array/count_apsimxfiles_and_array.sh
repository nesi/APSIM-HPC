#!/bin/bash

# Count the number of eligible .apsimx files
file_count=$(find . -maxdepth 1 -name "*.apsimx" ! -name "2023-10-09_MasterSoilApsimLibrary.apsimx" ! -name "LargerExample.apsimx" | wc -l)

# Check if there are any files to process
if [ "$file_count" -eq 0 ]; then
    echo "No eligible .apsimx files found. Exiting."
    exit 1
fi

# Generate the Slurm array directive
echo "Copy and paste the following line into your Slurm script:"
echo ""
echo "$(tput setaf 2)#SBATCH --array=1-$file_count$(tput sgr0)"
echo ""

# Print the list of files that will be processed
echo -e "\nThe following files will be processed:"
find . -maxdepth 1 -name "*.apsimx" ! -name "2023-10-09_MasterSoilApsimLibrary.apsimx" ! -name "LargerExample.apsimx" | sort
