### Sort .db files based on file size

`db-file-sort.py` does the following

1. It sets up the source directory and creates PASSED and FAILED directories if they don't exist.
2. It defines the size threshold as 20MB (converted to bytes).
3. terates through all files in the source directory.
4. For each .db file, it checks the file size:

   - If the size is greater than 20MB, it moves the file to the `PASSED` directory.
   - If the size is less than or equal to 20MB, it moves the file to the `FAILED` directory.
5. It prints a message for each file moved and a completion message at the end.


To use this script:

* Replace `source_dir = '.'` with the actual path to your directory containing the .db files.