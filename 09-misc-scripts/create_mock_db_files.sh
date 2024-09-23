#!/bin/bash

#Purpose of this script is to create a mock set of .db files with varying sizes for R&D purposes.
#This was used in compiling the 6-db-file-sorter/db-file-sort.py script

# Function to create a file of specific size
create_file() {
    filename=$1
    size=$2
    dd if=/dev/urandom of=$filename bs=1M count=$size status=progress
}

# Create 5 files larger than 20MB
for i in {1..5}; do
    size=$((RANDOM % 30 + 21))  # Random size between 21MB and 50MB
    create_file "large_${i}.db" $size
done

# Create 5 files smaller than 20MB
for i in {1..5}; do
    size=$((RANDOM % 19 + 1))  # Random size between 1MB and 19MB
    create_file "small_${i}.db" $size