#!/bin/bash

#Purpose of this script is to split the Config.txt files to mulitple directories
#This will assist with lowering the wait time to create the corresponding .apsimx files per txt file as it has to done via a serial for loop
#Default setting is to split the .txt files in current working directory to four sets
#One the split is done, make sure to copy the .met files and .apsimx files to each directory


# Create the directories
mkdir -p set-1 set-2 set-3 set-4

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
    done
}

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

echo "Split complete."
echo "Files in set-1: $(ls set-1 | wc -l)"
echo "Files in set-2: $(ls set-2 | wc -l)"
echo "Files in set-3: $(ls set-3 | wc -l)"
echo "Files in set-4: $(ls set-4 | wc -l)"
