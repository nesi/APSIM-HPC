#### `.slurm` script in this directory and the one in `../4-slurm-array` will:

1. Process 10 config files.
2. Use 4 CPUs and 8GB of memory per job.
3. Save Slurm output files in the format %A_%a.out in the "slurmlogs" directory.
4. Save output database files in the "OutputDatabases" directory.
5. Create a file named "database_list.txt" in the "OutputDatabases" directory, containing the names of all generated database files.

To load the database files in Python later, we can use the "database_list.txt" file:

```python
with open('OutputDatabases/database_list.txt', 'r') as f:
    database_files = [line.strip() for line in f]
```

