## Generate .apsimx and .db placeholder files from Config.txt files

1. Make sure to check the container image vesion (.aimg file) and double check the name of the ExampleConfig file ( template has `ExampleConfig.txt` )
3. `#SBATCH --time` variable will require revision based on the number of Config files. It takes **~25seconds** per file
2. Then submit the Slurm script with `sbatch create_apsimx_skip_failed.sl`
   - This is a serial process  due to https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/31
   - Refer to line 16-21 on the slurm script and adjust `max_consecutive_failures` to fit the following requirement
      - Expected number of consecutive failures *per* Soil Sample is equilvanet to number of .met weather files. Therefore, we recommend `max_consecutive_failures` = [ number of weather files + 1 ]
      - Reason for this implementation was discussed in https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/35

### Note on `if` `else` statement

`if [ -f "$file" ] && [ "$file" != "ExampleConfig.txt" ]; then:`

a. `[ -f "$file" ]`: Checks if the current `$file` is a regular file (not a directory or other special file).
b. `[ "$file" != "ExampleConfig.txt" ]`: Checks if the current `$file` is not named `"ExampleConfig.txt"`.

Both conditions must be true for the code inside the if block to execute.