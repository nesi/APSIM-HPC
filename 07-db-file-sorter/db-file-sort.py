#!/usr/bin/env python

import os
import shutil

# Set the source directory where your .db files are located
source_dir = '.'

# Create PASSED and FAILED directories if they don't exist
passed_dir = os.path.join(source_dir, 'PASSED')
failed_dir = os.path.join(source_dir, 'FAILED')
os.makedirs(passed_dir, exist_ok=True)
os.makedirs(failed_dir, exist_ok=True)

# Size threshold in bytes (20MB = 20 * 1024 * 1024 bytes)
size_threshold = 1 * 1024 * 1024

# Iterate through files in the source directory
for filename in os.listdir(source_dir):
    if filename.endswith('.db'):
        file_path = os.path.join(source_dir, filename)
        file_size = os.path.getsize(file_path)
        
        if file_size > size_threshold:
            destination = os.path.join(passed_dir, filename)
        else:
            destination = os.path.join(failed_dir, filename)
        
        # Move the file to the appropriate directory
        shutil.move(file_path, destination)
        print(f"Moved {filename} to {os.path.dirname(destination)}")

print("File sorting complete.")
