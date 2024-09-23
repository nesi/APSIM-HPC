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

