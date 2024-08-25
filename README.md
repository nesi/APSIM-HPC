# APSIM-eri-mahuika
Deploy APSIM on eRI and Mahuika clusters




<details>
<summary>June: Notes on how the config files were generated</summary>

* Extract SoilNames from CSV with `SoilNames <- as.vector(unlist(read.csv("SubsetSoilName.csv"))`
* R script generate the config file/s ( one config file per Soil sample  per Weather file)
  * Alsmost all of the SoilNames exist. Weather files willl change but it shouldn't be a problem as we "catch" by them by using the unique `.met` file extension
* config files should have both the soil names and weather names ( that pattern will not change) . In R scrip Soli name is `$var1`
* Config files should be on the curernt working directory. ( hard-coded on APSIM)
* The base Config file should contain the correct name of the soil library to load soils from, as well as the correct Example file containing the simulations to run on the correct soil and weather files

</details>


# 1-apptainer-build

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

# 2-apsim-module

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



# 3-generate-config-files

### `generate_apsim_configs.py` script does the following:

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

>This script will generate a separate config file for each combination of soil name and weather file, naming each file appropriately and placing it in the specified output directory, `ConfigFiles`

# 5-snakemake

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

