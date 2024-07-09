#!/bin/bash -e 

export hostname=$(hostname)


if [ "$hostname" = "mahuika01" ] 
then
	sbatch mahuika-submit.slurm
else 
    sbatch eri-submit.slurm
fi




