#!/bin/bash

# Color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Ask for the working directory
echo -e "${YELLOW}Provide the path to working directory for apsim_simulations:${NC} \c"
read -r working_dir

# Check if the directory exists, if not create it
if [ ! -d "$working_dir" ]; then
    mkdir -p "$working_dir"
    echo "Created directory: $working_dir"
fi

# Copy the R script
cp 03-generate-config-files/generate_apsim_configs.R "$working_dir"

# Copy the Snakefile_txt
cp 08-snakemake/Snakefile_txt "$working_dir"

# Copy the Snakefile_apsimx
cp 08-snakemake/Snakefile_apsimx "$working_dir"

# Print completion message
echo -e "\nSetup is complete. Switching to working directory now."

# Change to the working directory
cd "$working_dir" || exit

# Print current directory to confirm
echo -e "${GREEN}${BOLD}Current working directory: $(pwd)${NC}"
