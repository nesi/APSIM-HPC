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

# Check if FAILED_CONFIG is empty and FAILED_DB has at most one file
if [ -z "$(ls -A FAILED_CONFIG 2>/dev/null)" ] && [ $(ls -1 FAILED_DB 2>/dev/null | wc -l) -le 1 ]; then
    echo "FAILED_CONFIG is empty and FAILED_DB has at most one file. Cleaning up files..."
    
    # Delete files with .processed and .apsimx extensions
    find . -maxdepth 1 -type f \( -name "*.processed" -o -name "*.apsimx" -o -name "*.txt" -o -name "*.met" \) -delete
    
    # Delete txt_files_processed and db_files_sorted files
    rm -f txt_files_processed db_files_sorted
    
    echo "Cleanup completed."
else
    echo "FAILED_CONFIG is not empty or FAILED_DB has more than one file. Skipping cleanup."
fi
