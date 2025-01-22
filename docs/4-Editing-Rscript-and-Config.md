#Editing R script and config file

In the current setup, the R script will generate config files for all possible soil and weather file combinations. More commonly, one would have a specific experimental design in mind. To avoid running a number of models that are not wanted, instead of using all possible combinations, the experimental design can be loaded from a csv file. This csv file also needs to be saved in the working directory together with the config file template. 

The csv file needs two columns, with Soil names in one column and weather files in another column. The easiest way to alter the R script is to remove the lines loading soil names and weather files (lines 6 and 7) as well as the lines that creates the experimental design (line 25) and loading the csv file with the experimental design by adding the following lines

```r
Des <- read.csv('CsvFileName.csv')
colnames(Des) <- c('Var1', 'Var2')
```

If you instead wish to change different parameters (i.e., not only soil and weather) over the modelling iterations, the config file needs to be changed to have a generic name for the parameter you wish to change (Instructions on how to write an apsim config file is available at https://apsimnextgeneration.netlify.app/usage/editfile/), as well as its own column in the csv file (suggestedly named 'Var3' if you wish to keep the other two as well). The R script will also need to be updated to include this new variable. This is done by adding one extra line where the config files are created such as:

```r
Config <- gsub(pattern = 'VariableName', replacement = Des$Var3[i], Config)
```
Where VariableName should be replaced with the keyword written in the config file. 


To to prevent files from being overwritten, Des$Var3 also needs to be added to the file name by changing the line

```r
ConfigFilePath <- paste0("./", Des$Var1[i], "_", Des$Var2[i], "ConfigFile.txt")
```
To 

```r
ConfigFilePath <- paste0("./", Des$Var1[i], "_", Des$Var2[i], "_", Des$Var3[i], "ConfigFile.txt")
```

