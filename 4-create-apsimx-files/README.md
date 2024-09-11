## Generate .apsimx and .db placeholder files from Config.txt files

1. Make sure to check the container image vesion (.aimg file) and double the name of the ExampleConfig file ( template has `ExampleConfig.txt` )
3. `#SBATCH --time` variable will require revision based on the number of Config files. It takes ~25seconds per file
2. Then submit the Slurm script with `sbatch create_apsimx.sl`
   - This is a serial process  due to https://github.com/DininduSenanayake/APSIM-eri-mahuika/issues/31