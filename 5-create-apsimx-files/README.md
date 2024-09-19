## Generate .apsimx and .db placeholder files from Config.txt files

1. Make sure to check the container image vesion (.aimg file) and double check the name of the ExampleConfig file ( template has `ExampleConfig.txt` )
3. `#SBATCH --time` variable will require revision based on the number of Config files. It takes **~25seconds** per file
2. Then submit the Slurm script with `sbatch create_apsimx_skip_failed.sl`
   - This is a serial process  due to https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/31
   - Refer to line 16-21 on the slurm script and adjust `max_consecutive_failures` to fit the following requirement
      - Expected number of consecutive failures *per* Soil Sample is equilvanet to number of .met weather files. Therefore, we recommend `max_consecutive_failures` = [ number of weather files + 1 ]
      - Reason for this implementation was discussed in https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/35


## `restart_create_apsimx_skip_failed.sl`

* Purpose of this script is to address https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/48. .i.e. In an instance where the above script is to time out,etc. this restart script will
pick up the .txt files which weren't subject to `Models --apply` command and it will restart from the failed point.
* This script has to be submitted from the same working directory where the above Slurm script was submitted. Also, it expects the `slurmlog/{timedout}.out` which is the standrd out from previous timedout/failed job to be on the 
slurmlogs directory as it uses the entires on that file to identify the "Successfully" processed .txt files

1. It uses the same SLURM configuration and Apptainer setup as your original script.
2. You will be required to enter the failed/timed out JOBID to `FAILED_JOB_ID="Enter the timedout/failed jobID"``
3. Extracts the list of successfully processed files from this log file.
4. Then iterates through all .txt files in both the working directory and the FAILED directory, skipping "ExampleConfig.txt".
5. For each file, it checks if it has already been successfully processed (by looking for its name in the extracted list from the log file).

* If successful, it resets the consecutive failure counter.
* If the successfully processed file was in the `FAILED` directory, it moves it back to the working directory.
* If processing fails, it moves the file to the `FAILED` directory and increments the consecutive failure counter.


It maintains the same consecutive failure limit as your original script.


### Note on `if` `else` statement

`if [ -f "$file" ] && [ "$file" != "ExampleConfig.txt" ]; then:`

a. `[ -f "$file" ]`: Checks if the current `$file` is a regular file (not a directory or other special file).
b. `[ "$file" != "ExampleConfig.txt" ]`: Checks if the current `$file` is not named `"ExampleConfig.txt"`.

Both conditions must be true for the code inside the if block to execute.
