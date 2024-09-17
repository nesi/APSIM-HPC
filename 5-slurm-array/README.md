## Auto-generate the `#SBATCH --array` variable and Submit the Slurm array 

1. Run `count_apsimxfiles_and_array.sh` script first which will generate the `#SBATCH --array` variable with the number of array tasks based on the number of Config files ( and .db placeholder files). Copy and paste that variable to `array_create_db_files.sl` Slurm variables header section
2. Then submit the array script with `sbatch array_create_db_files.sl`