### Sort .db files based on file size

`db-file-sort.py` does the following

1. It sets up the source directory and creates `PASSED` and `FAILED` directories if they don't exist.
2. It defines the size threshold as 1 MB `size_threshold = 1 * 1024 * 1024` (converted to bytes). 
3. terates through all files in the source directory.
4. For each .db file, it checks the file size:

   - If the size is greater than 1MB, it moves the file to the `PASSED` directory.
   - If the size is less than or equal to 1MB, it moves the file to the `FAILED` directory.
5. It prints a message for each file moved and a completion message at the end.


To use this script:

* Replace `source_dir = '.'` in line 7 with the actual path to your directory containing the .db files.