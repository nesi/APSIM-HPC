#!/bin/bash

echo ""
VERSION="1.5.0"  # Replace with your actual version
UPDATE_TIME="2024-10-16"  # Replace with your actual update time

TITLE_DOC=$(cat << EOF          
          \e[44;37m             APSIM-HPC: Agricultural Production Systems               \e[0m
          \e[44;37m              Simulator - High Performance Computing                  \e[0m
          \e[47;32m               Author  :  AgR-NeSI                                    \e[0m
          \e[47;32m               Version :  $VERSION                                       \e[0m
          \e[47;32m               Update  :  $UPDATE_TIME                                  \e[0m
EOF
)

echo -e "$TITLE_DOC"

# Color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color
BOLD='\033[1m'


echo ""
echo ""
# Ask for the working directory
echo -e "${YELLOW}Provide the path to working directory for apsim_simulations:${NC} \c"
read -r working_dir

echo ""

# Check if the directory exists, if not create it
if [ ! -d "$working_dir" ]; then
    mkdir -p "$working_dir"
    echo "Created directory: $working_dir"
fi

# Copy the R script
cp 03-generate-config-files/generate_apsim_configs.R "$working_dir"

# Copy the Snakefile_txt
cp 08-snakemake/Snakefile_1 "$working_dir"

# Copy the Snakefile_apsimx
cp 08-snakemake/Snakefile_2 "$working_dir"

#Copy the run_snakefile.sh
cp 08-snakemake/run_snakefile.sh "$working_dir"

#Copy snakemake profile 08-snakemake/profiles to ~/.config/snakemake
mkdir -p ~/.config/snakemake
if [ ! -d ~/.config/snakemake/slurm ]; then
    cp -r 08-snakemake/profiles/slurm ~/.config/snakemake/
fi

# Print completion message
echo -e "\nSwitching to working directory now and running generate_apsim_configs.R to create config files."
echo ""

# Change to the working directory
cd "$working_dir" || exit

# Print current directory to confirm
echo -e "${GREEN}${BOLD}Current working directory: $(pwd)${NC}"
echo ""

#Load modules 
echo -e "${YELLOW}Loading required modules and copying nesi Snakemake profile...${NC}"
if [[ $(hostname) == *eri* ]]; then
  module purge && module load snakemake/7.32.3-foss-2023a-Python-3.11.6 R/4.4.1-foss-2023a Graphviz/12.1.2
elif [[ $(hostname) == *mahuika* ]]; then
  module purge >/dev/null 2>&1 && module load snakemake/7.32.3-gimkl-2022a-Python-3.11.3 R/4.3.1-gimkl-2022a
fi

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

echo ""


# Ask if the user wants to submit the APSIM-HPC workflow
echo -n -e "${YELLOW}Would you like to submit the APSIM-HPC workflow to generate .db files? (yes/no) : ${NC}"
read -r submit_answer

echo ""

if [ "${submit_answer,,}" = "yes" ]; then
    # Verify the user is in the correct directory
    if [ "$(pwd)" != "$working_dir" ]; then
        echo -e "${RED}Error: Not in the correct working directory. Please run the script again.${NC}"
        exit 1
    fi

    # Execute the command to submit jobs
    echo -e "${YELLOW}Submitting APSIM-HPC workflow jobs...${NC}"
    find . -type d -name "Set*" -exec sh -c 'cd "{}" && nohup ./run_snakefile.sh > output.log 2>&1 &' \;

    echo -e "${GREEN}${BOLD}Slurm jobs were submitted. Check the status with "squeue --me" command${NC}"
else
    echo -e "${YELLOW}APSIM-HPC workflow submission skipped.${NC}"
fi
