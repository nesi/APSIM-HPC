#!/usr/bin/env Rscript
###Create config files


library(tidyr)
SoilNames <- as.vector(unlist(read.csv("SubsetSoilName.csv"))) ##List of soil names that must exist in the Soil Library .apsimx file (most likely supplied by experienced APSIM user)
WeatherFiles <- list.files('./', pattern = "\\.met$") %>% gsub('.met', '', .) ##Listing all available weather files.
ConfigTemplate <- "ExampleConfig.txt" ##Base config file

#Create a vector of all soil names available in the soil library
SoilLibrary <- "2023-10-09_MasterSoilApsimLibrary.apsimx" ###Change name to the soil library you are using
AvailableSoilNames <- readLines(SoilLibrary)
AvailableSoilNames <- AvailableSoilNames[grep('LocalName', AvailableSoilNames)]
AvailableSoilNames <- gsub("\"", "", AvailableSoilNames)
AvailableSoilNames <- gsub(" ", "", AvailableSoilNames)
AvailableSoilNames <- gsub("LocalName:", "", AvailableSoilNames)
AvailableSoilNames <- gsub(",", "", AvailableSoilNames)


#Temporary Subset of soilNames
SoilNames <- SoilNames[1:10]


Des <- expand.grid(SoilNames, WeatherFiles) #make factorial design from factors given

DBNames <- vector() ##Object initiation
apsimxNames <- vector()

CreateConfigFiles <- function(ConfigTemplate, Des){
  for(i in 1:nrow(Des)){
    if(Des$Var1[i] %in% AvailableSoilNames){
    #Read Base config file and change variables to correct names
    Config <- readLines(ConfigTemplate)
    Config <- gsub(pattern = 'SoilName', replacement = Des$Var1[i], Config)
    Config <- gsub(pattern = 'WeatherFileName', replacement = Des$Var2[i], Config)

    #Write config information to a new txt file
    ConfigFilePath <- paste0("./", Des$Var1[i], "_", Des$Var2[i], "ConfigFile.txt")
    fileConn <- file(ConfigFilePath)
    writeLines(Config, fileConn)
    close(fileConn)

    #save db names in a vector so that they can be saved and loaded into python
    apsimxNames[i] <- paste0(Des$Var2[i], "_", Des$Var1[i], ".apsimx")
    DBNames[i] <- paste0(getwd(), "/", Des$Var2[i], "_", gsub(" ", "",Des$Var1[i]), '.db') 
    } else {
      cat(paste0("\n", Des$Var1[i], " does not exist in the selected Soil library"))
    }
    
  }
  out <- data.frame(apsimxNames, DBNames)
  write.csv(out, file = "FileAndDBNames.csv")
}

CreateConfigFiles(ConfigTemplate, Des)
