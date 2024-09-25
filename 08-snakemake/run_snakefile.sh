#!/bin/bash

# Set the number of jobs for parallel processing of APSIM files
APSIM_JOBS=100

# Run Snakefile_txt
echo "Processing text files..."
snakemake -s Snakefile_txt --profile slurm --jobs 1

# Check if the previous command was successful
if [ $? -eq 0 ]; then
    echo "Text file processing completed successfully."
    
    # Run Snakefile_apsimx
    echo "Processing APSIM files..."
    snakemake -s Snakefile_apsimx --profile slurm --jobs $APSIM_JOBS
    
    if [ $? -eq 0 ]; then
        echo "APSIM file processing completed successfully."
    else
        echo "Error: APSIM file processing failed."
        exit 1
    fi
else
    echo "Error: Text file processing failed."
    exit 1
fi

echo "All processing completed."