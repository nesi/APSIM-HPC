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


