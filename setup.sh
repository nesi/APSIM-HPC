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

#Copy the run_snakefile.sh
cp 08-snakemake/run_snakefile.sh "$working_dir"

# Print completion message
echo -e "\nSwitching to working directory now and running generate_apsim_configs.R to create config files."

# Change to the working directory
cd "$working_dir" || exit

# Print current directory to confirm
echo -e "${GREEN}${BOLD}Current working directory: $(pwd)${NC}"


# Execute the R script
echo -e "${YELLOW}Generating config files and splitting into multiple sets...${NC}"
Rscript generate_apsim_configs.R

echo ""

# Copy run_snakefile.sh to all directories starting with "Set"
echo -e "${YELLOW}Copying run_snakefile.sh to all Set directories...${NC}"
for dir in Set*/; do
    if [ -d "$dir" ]; then
        cp run_snakefile.sh "$dir"
        echo "Copied run_snakefile.sh to $dir"
    fi
done

# Print completion message
echo -e "${GREEN}${BOLD}Config files generation complete.${NC}"
