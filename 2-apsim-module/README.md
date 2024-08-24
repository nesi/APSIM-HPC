`generate_lua.py` script does the following:

1. Prompts the user to enter the name of the container image.
2. Validates the image name format to ensure it follows the convention "apsim-YYYY.MM.XXXX.Y.aimg".
3. Extracts the version from the image name.
4. checks if the image file exists in the "../../container/" directory.
5. If everything is valid, it creates a new .lua file with the filename "Version.lua" (e.g., "2024.08.7572.0.lua") in the `APSIM/`directory.
6. The generated .lua file includes the correct version in the "whatis" statement.

To use this script: Run `./generate_lua.py` in the same directory where you want the .lua files to be created.
