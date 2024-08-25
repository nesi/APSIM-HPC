#!/usr/bin/env Rscript

#Proof of concept script for apsim job submission
library(tidyr)

SoilNames <- c("Ahuriri_5a1", "Otorohanga_67a1", "Temuka_65a1") ##List of soil names that must exist in the Soil Library .apsimx file (most likely supplied by experienced APSIM user)
WeatherFiles <- list.files('./', pattern = "\\.met$") %>% gsub('.met', '', .) ##Listing all available weather files.

# Define the container command
ContainerCommand <- "apptainer exec /agr/persist/projects/2024_apsim_improvements/APSIM-eri-mahuika/apsim-simulations/container/apsim-2024.08.7572.0.aimg Models"

OrigConfigFilePath <- "ExampleConfig.txt" ##Base config file

Des <- expand.grid(SoilNames, WeatherFiles) #make factorial design from factors given
DBNames <- vector() ##Object initiation

for(i in 1:nrow(Des)){
  #Read Base config file and change variables to correct names
  ConfigFilePath <- ".\\ConfigFile.txt" ##Name of temporary file that is created for each iteration
  Config <- readLines(OrigConfigFilePath)
  Config <- gsub(pattern = 'SoilName', replacement = Des$Var1[i], Config)
  Config <- gsub(pattern = 'WeatherFileName', replacement = Des$Var2[i], Config)
  
  #Write config information to a new txt file
  fileConn <- file(ConfigFilePath)
  writeLines(Config, fileConn)
  close(fileConn)
  
  #Execute command via system (instead of shell)
  command <- paste(ContainerCommand, "--apply", ConfigFilePath)
  system(command)
  
  #save db names in a vector so that they can be saved and loaded into python
  DBNames[i] <- paste0(getwd(), "/", Des$Var2[i], "_", Des$Var1[i], '.db')
}
