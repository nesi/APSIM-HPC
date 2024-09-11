## Use `generate_apsim_configs.R` to generate the Config files

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
