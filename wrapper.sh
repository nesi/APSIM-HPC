#!/bin/bash -e 

export CLUSTER="mahuika"


if [ "$CLUSTER" = "mahuika" ] 
then
	sbatch mahuika-submit.slurm
else 
    sbatch eri-submit.slurm
fi




