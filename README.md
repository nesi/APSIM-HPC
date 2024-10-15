# APSIM-HPC (https://nesi.github.io/APSIM-HPC/)
Deploy APSIM (Agricultural Production Systems sIMulator - https://www.apsim.info/) on high performance computing clusters. 


<details>
<summary>June: Notes on how the config files were generated</summary>

* Extract SoilNames from CSV with `SoilNames <- as.vector(unlist(read.csv("SubsetSoilName.csv"))`
* R script generate the config file/s ( one config file per Soil sample  per Weather file)
  * Alsmost all of the SoilNames exist. Weather files willl change but it shouldn't be a problem as we "catch" by them by using the unique `.met` file extension
* config files should have both the soil names and weather names ( that pattern will not change) . In R scrip Soli name is `$var1`
* Config files should be on the curernt working directory. ( hard-coded on APSIM)
* The base Config file should contain the correct name of the soil library to load soils from, as well as the correct Example file containing the simulations to run on the correct soil and weather files

</details>


# 01-apptainer-build

### How to launch the apptainer build

1. Run `./updateversion-and-build.sh` and respond to prompts 
2. Once the image built was completed, execute "clean.sh"

#### What does the `updateversion-and-build.sh` do 

1. It will ask to define the APSIM Release information ( .deb version). Current release branch has the format of "2024.07.7572.0" and the prompts will request to provide information for "2024.07" in `Enter Year and Month (YYYY.MM)` followed by `Enter TAG:` which is equivalent to  `7572` in above example
2. This will auto-update the corresponding fields in **Apptainer.def** under `%arguments`, add the tag to `curl --silent -o ${APPTAINER_ROOTFS}/ApsimSetup.deb https://builds.apsim.info/api/nextgen/download/${TAG}/Linux` and complete the `%setup` on the same def file
3. Then it will ask `Would you like to submit the container build Slurm job? (Yes/No):` which we recommend answering `Yes`as it will auto update the `export APSIM_VERSION=` and   `export CACHETMPDIR=` based on the cluster of choice

#### Path to new container image. 

We are using  a relative path as defined in `build-container.def`

```bash
13	export IMAGE_PATH="../../apsim-simulations/container/"
```

[apptainer-build.webm](https://github.com/user-attachments/assets/a342fcd4-55e9-4615-896b-7eac46368e84)


# 02-apsim-module

### Generate the .lua file
`generate_lua.py` script does the following:

1. Prompts the user to enter the name of the container image.
2. Validates the image name format to ensure it follows the convention "apsim-YYYY.MM.XXXX.Y.aimg".
3. Extracts the version from the image name.
4. checks if the image file exists in the "../../container/" directory.
5. If everything is valid, it creates a new .lua file with the filename "Version.lua" (e.g., "2024.08.7572.0.lua") in the `APSIM/`directory.
6. The generated .lua file includes the correct version in the "whatis" statement.

To use this script: Run `./generate_lua.py` in the same directory where you want the .lua files to be created.

### This module file (.lua) does the following

This module file does the following:

1. Provides basic information about the module using whatis statements.
2. Adds `/usr/local/bin` and `/usr/bin` from the container to the system's `PATH`.
3. Sets the `R_LIBS_USER` environment variable to `/usr/local/lib/R/site-library`.
4. Creates aliases for executables within the container, so they can be run directly from the command line.
5. Sets an environment variable `APSIM_IMAGE` with the path to the Apptainer image.

### How to use the module:

Adjust the list of executables in the `create_exec_alias` section as needed for your specific use case.

```bash
module use APSIM/
module load APSIM/2024.08.7572.0
```
* If the version is not specified, `module load APSIM` will load the latest version



# 03-generate-config-files

## Use `generate_apsim_configs.R` to generate the Config files

>This script will generate a separate config file for each combination of soil name and weather file, naming each file appropriately and placing it in the specified output directory, `ConfigFiles`


<br>


<details>

<summary> BUG TO BE FIXED : `generate_apsim_configs.py` which is a backup to .R script but it is buggy at the moment</summary>

1. reads soil names from the `CSV` file.
2. gets all `.met` files from the **/Weather** directory.
3. reads the base config file.
4. generates a new config file for each combination of soil name and weather file.
5. replaces the placeholders in the config with the correct soil name and weather file name.
6. saves each new config file with a name that includes both the weather file name and soil name.

.
### To use this script:

1. Make sure you have the SubsetSoilName.csv, Weather directory with .met files, and ExampleConfig.txt in the same directory as the script (or adjust the paths in the script).
2. Create a directory named `ConfigFiles` for the output (or change the output_dir in the script).
3. `./generate_apsim_configs.py`
</details>



# 04-split-configtxt-files-to-sets

## `split_configfiles_to_sets.sh`

Default setting of this script will split .txt files in the current working directory to four separate directories, `set-1`, `set-2` , `set-3` and `set-4`


# 05-create-apsimx-files

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


# 06-slurm-array

## Auto-generate the `#SBATCH --array` variable and Submit the Slurm array 

1. Run `count_apsimxfiles_and_array.sh` script first which will generate the `#SBATCH --array` variable with the number of array tasks based on the number of Config files ( and .db placeholder files). Copy and paste that variable to `array_create_db_files.sl` Slurm variables header section
2. Then submit the array script with `sbatch array_create_db_files.sl`

# 07-db-file-sorter

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

# 08-snakemake

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



# 09-misc-scripts

## `create_mock_db_files.sh`

Default version of this script will:

- Create 5 files with names like *large_1.db, large_2.db*, etc., each between 21MB and 50MB in size.
- Create 5 files with names like *small_1.db, small_2.db*, etc., each between 1MB and 19MB in size.
- Use random data to fill the files.
- Show a progress bar for each file creation.

Please note:

- This script uses `/dev/urandom` as a source of random data, which might be slow for creating large files. For faster (but less random) file creation, you could replace `/dev/urandom` with `/dev/zero`.
- The exact sizes will vary each time you run the script due to the use of random numbers.
- The script will create files in the current directory.

<details>
</summary>Example</summary>
```bash
$ ./create_db_files.sh 
46+0 records in
46+0 records out
48234496 bytes (48 MB) copied, 0.330022 s, 146 MB/s
43+0 records in
43+0 records out
45088768 bytes (45 MB) copied, 0.279238 s, 161 MB/s
44+0 records in
44+0 records out
46137344 bytes (46 MB) copied, 0.26549 s, 174 MB/s
49+0 records in
49+0 records out
51380224 bytes (51 MB) copied, 0.335017 s, 153 MB/s
27+0 records in
27+0 records out
28311552 bytes (28 MB) copied, 0.167217 s, 169 MB/s
10+0 records in
10+0 records out
10485760 bytes (10 MB) copied, 0.0601622 s, 174 MB/s
13+0 records in
13+0 records out
13631488 bytes (14 MB) copied, 0.0829061 s, 164 MB/s
5+0 records in
5+0 records out
5242880 bytes (5.2 MB) copied, 0.0304713 s, 172 MB/s
3+0 records in
3+0 records out
3145728 bytes (3.1 MB) copied, 0.0186602 s, 169 MB/s
11+0 records in
11+0 records out
11534336 bytes (12 MB) copied, 0.0661401 s, 174 MB/s
File creation completed.
```
```bash
$ $ find ./ -name "*.db" -type f -exec du -h {} + | sort -rh
49M	./large_4.db
46M	./large_1.db
44M	./large_3.db
43M	./large_2.db
27M	./large_5.db
13M	./small_2.db
11M	./small_5.db
10M	./small_1.db
5.0M	./small_3.db
3.0M	./small_4.db
```
</details>



