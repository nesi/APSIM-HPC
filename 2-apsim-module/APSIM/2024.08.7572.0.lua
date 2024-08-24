-- apsim.lua

-- Load Apptainer as a dependency
load("Apptainer")

-- Module description
whatis("Name: APSIM")
whatis("Version: 2024.08.7572.0")
whatis("Description: The Leading Software Framework for Agricultural Systems Modelling and Simulation")
whatis("URL: https://www.apsim.info/")

-- Define the Apptainer image path
local image = "../../container/apsim-2024.08.7572.0.aimg"

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
create_exec_alias("Models")
create_exec_alias("R")
create_exec_alias("Rscript")
-- Add more executables as needed

-- If you want to set the Apptainer image as a variable that can be used elsewhere
setenv("APSIM_IMAGE", image)
