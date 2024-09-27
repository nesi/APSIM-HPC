#!/bin/bash

#Purpose of this script is to split the Config.txt files to mulitple directories
#This will assist with lowering the wait time to create the corresponding .apsimx files per txt file as it has to done via a serial for loop
#Default setting is to split the .txt files in current working directory to four sets
#One the split is done, make sure to copy the .met files and .apsimx files to each directory


# Function to display progress message
show_progress() {
    local message="$1"
    echo -ne "\r$message..."
}

# Create the directories , set-1, set-2,etc and slurmlogs directory inside each of those to host standard out/err
# Latter is due to https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/43. We can remove the requirement
# in few years as older Slurm versions will be deprecated
mkdir -p set-{1..4}/slurmlogs

# Get all .txt files. Expect the .txt files to be in the current working directory
txt_files=(*.txt)
total_files=${#txt_files[@]}

# Calculate the number of files per set
files_per_set=$((total_files / 4))
remainder=$((total_files % 4))

# Function to move files to a set
move_files_to_set() {
    local set_number=$1
    local start_index=$2
    local end_index=$3
    for ((i=start_index; i<end_index; i++)); do
        mv "${txt_files[i]}" "set-$set_number/"
        show_progress "Splitting in Progress"
    done
}

echo "Starting to split files..."

# Move files to each set
start_index=0
for set in {1..4}; do
    end_index=$((start_index + files_per_set))
    # Add one more file to this set if there are remaining files
    if [ $set -le $remainder ]; then
        end_index=$((end_index + 1))
    fi
    move_files_to_set $set $start_index $end_index
    start_index=$end_index
done

echo -e "\nSplit complete."
echo "Files in set-1: $(ls set-1 | wc -l)"
echo "Files in set-2: $(ls set-2 | wc -l)"
echo "Files in set-3: $(ls set-3 | wc -l)"
echo "Files in set-4: $(ls set-4 | wc -l)"

# Copy .met and .apsimx files to each set directory
echo "Copying .met and .apsimx files to each set directory..."
for set in {1..4}; do
    cp *.met "set-$set/"
    cp *.apsimx "set-$set/"
    show_progress "Copying files to set-$set"
done

echo -e "\nCopying complete."
echo ".met files copied to each set: $(ls *.met | wc -l)"
echo ".apsimx files copied to each set: $(ls *.apsimx | wc -l)"
