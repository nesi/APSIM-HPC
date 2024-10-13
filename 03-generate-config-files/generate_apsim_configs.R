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


SplitConfigFilesIntoSets <- function(ConfigFiles, nSets = 1){
  nFiles <- length(ConfigFiles)
  FilesPerSet <- rep(floor(nFiles/nSets), times = nSets)
  FilesLeftOver <- nFiles%%nSets
  if(FilesLeftOver!=0) FilesPerSet[1:FilesLeftOver] <- FilesPerSet[1:FilesLeftOver] + 1 ##To include an uneven number of files
  Sets <- paste0('Set-', 1:nSets)
  for(i in 1:length(Sets)){
    FilesRemaining <- list.files(pattern = "ConfigFile.txt$")
    if(!dir.exists(Sets[i])) dir.create(Sets[i])
    file.rename(FilesRemaining[1:FilesPerSet[i]], paste0(Sets[i], "/", FilesRemaining[1:FilesPerSet[i]]))
    cat(paste0("\nFiles in ", Sets[i], " ", length(list.files(Sets[i], pattern = 'ConfigFile.txt$'))))

    metFiles <- list.files(pattern = '.met$')
    file.copy(metFiles, paste0(Sets[i], "/", metFiles))
    apsimxFiles <- list.files(pattern = '.apsimx$')
    file.copy(apsimxFiles, paste0(Sets[i], "/", apsimxFiles))
    SmakeFiles <- list.files(pattern = 'Snakefile')
    file.copy(SmakeFiles, paste0(Sets[i], "/", SmakeFiles))

  }
  cat("\nCopying complete")
  cat(paste0("\n.met files copied to each set: ", length(list.files(pattern = ".met$"))))
  cat(paste0("\n.apsimx files copied to each set: ", length(list.files(pattern = ".apsimx$"))))
  cat(paste0("\n.Snakemake files copied to each set: ", length(list.files(pattern = "Snakefile"))))


}


CreateConfigFiles(ConfigTemplate, Des)

SplitConfigFilesIntoSets(list.files(pattern = "ConfigFile.txt$"), nSets = 3)
