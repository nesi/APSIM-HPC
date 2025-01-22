#!/bin/bash

# Exit on error
set -e

# Configuration
APSIM_JOBS=100
MAX_WORKFLOW_RETRIES=3
RETRY_DELAY=60  # seconds

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to perform cleanup after successful run
cleanup_files() {
    log_message "Checking conditions for cleanup..."
    
    if [ -z "$(ls -A FAILED_CONFIG 2>/dev/null)" ] && [ $(ls -1 FAILED_DB 2>/dev/null | wc -l) -le 1 ]; then
        log_message "FAILED_CONFIG is empty and FAILED_DB has at most one file. Starting cleanup..."
        
        # Delete files with specified extensions
        find . -maxdepth 1 -type f \( -name "*.processed" -o -name "*.apsimx" -o -name "*.txt" -o -name "*.met" \) -delete
        
        # Delete processing status files
        rm -f txt_files_processed db_files_sorted
        
        log_message "Cleanup completed successfully"
        return 0
    else
        log_message "FAILED_CONFIG is not empty or FAILED_DB has more than one file. Skipping cleanup."
        return 1
    fi
}


# Function to run a Snakefile with comprehensive retry and recovery logic
run_snakefile() {
    local snakefile=$1
    local jobs=$2
    local retry_count=0
    local success=false

    while [ $retry_count -lt $MAX_WORKFLOW_RETRIES ] && [ "$success" = false ]; do
        log_message "Attempting to run $snakefile (Attempt $((retry_count + 1)))"

        # Run Snakemake with full verbosity and rerun-incomplete
        if snakemake -s "$snakefile" --profile slurm --jobs "$jobs" --rerun-incomplete -p; then
            success=true
            log_message "$snakefile completed successfully"
        else
            ((retry_count++))

            # Check for specific failure conditions
            if [ -f failed_txt_files.log ]; then
                failed_count=$(wc -l < failed_txt_files.log)
                log_message "Number of failed files: $failed_count"
                
                # Optional: Add logic to handle specific failure scenarios
                if [ "$failed_count" -gt 0 ]; then
                    log_message "Examining failed files in FAILED_CONFIG"
                    ls -l FAILED_CONFIG/
                fi
            fi

            if [ $retry_count -lt $MAX_WORKFLOW_RETRIES ]; then
                log_message "Workflow failed. Waiting $RETRY_DELAY seconds before retry..."
                sleep $RETRY_DELAY
            else
                log_message "Workflow failed after $MAX_WORKFLOW_RETRIES attempts"
                return 1
            fi
        fi
    done

    return 0
}

# Main workflow execution
main() {
    local workflow_success=true

    # Process Snakefile_1
    if ! run_snakefile "Snakefile_1" 1; then
        log_message "Error: Text file processing failed"
        workflow_success=false
        exit 1
    fi

    # Process Snakefile_2
    if ! run_snakefile "Snakefile_2" "$APSIM_JOBS"; then
        log_message "Error: APSIM file processing failed"
        workflow_success=false
        exit 1
    fi

    if [ "$workflow_success" = true ]; then
        log_message "Workflow completed successfully"
        
        # Attempt cleanup
        if cleanup_files; then
            log_message "Post-processing cleanup completed successfully"
        else
            log_message "Warning: Cleanup skipped due to failed conditions"
        fi
    fi
}


# Trap for handling interrupts
trap 'log_message "Workflow interrupted"' INT TERM

# Execute main workflow
main
