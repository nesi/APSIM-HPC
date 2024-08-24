#!/usr/bin/env python3

import os
import re

def create_lua_file(version, image_name):
    lua_content = f'''-- apsim.lua

-- Module description
whatis("Name: APSIM")
whatis("Version: {version}")
whatis("Description: This is a module for the APSIM Apptainer container")
whatis("URL: https://www.apsim.info/")

-- Define the Apptainer image path
local image = "../../container/{image_name}"

-- Function to prepend a path to an environment variable
local function prependPath(envVar, path)
    local oldVal = os.getenv(envVar) or ""
    if oldVal:match("^" .. path) then
        return  -- Path is already at the beginning, do nothing
    end
    prepend_path(envVar, path)
end

-- Add container paths to PATH
prependPath("PATH", "/usr/local/bin")
prependPath("PATH", "/usr/bin")

-- Set R_LIBS_USER
setenv("R_LIBS_USER", "/usr/local/lib/R/site-library")

-- Set up Apptainer executable command
local apptainer_exec = "apptainer exec " .. image .. " "

-- Function to create aliases for executables
local function create_exec_alias(exec_name)
    set_alias(exec_name, apptainer_exec .. exec_name)
end

-- Create aliases for common executables (add or remove as needed)
create_exec_alias("apsim")
create_exec_alias("R")
create_exec_alias("Rscript")
-- Add more executables as needed

-- If you want to set the Apptainer image as a variable that can be used elsewhere
setenv("APSIM_IMAGE", image)
'''

    with open(f"APSIM/{version}.lua", "w") as lua_file:
        lua_file.write(lua_content)

def main():
    # Ask user for the container image name
    image_name = input("Please enter the name of the container image (e.g., apsim-2024.08.7572.0.aimg): ")

    # Validate the image name format
    if not re.match(r'^apsim-\d+\.\d+\.\d+\.\d+\.aimg$', image_name):
        print("Invalid image name format. It should be like 'apsim-YYYY.MM.XXXX.Y.aimg'")
        return

    # Extract version from the image name
    version = image_name.split('-')[1].rsplit('.', 1)[0]

    # Check if the image exists in the ../../container/ directory
    if not os.path.exists(f"../../container/{image_name}"):
        print(f"Error: The file {image_name} does not exist in the ../../container/ directory.")
        return

    # Create the .lua file
    create_lua_file(version, image_name)
    print(f"Created APSIM/{version}.lua successfully.")

if __name__ == "__main__":
    main()
