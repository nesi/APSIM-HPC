### How to launch the apptainer build

1. Run `./updateversion-and-build.sh` and respond to prompts 
2. Once the image built was completed, execute "clean.sh"

#### What does the `updateversion-and-build.sh` do 

1. It will ask to define the APSIM Release information ( .deb version). Current release branch has the format of "2024.07.7572.0" and the prompts will request to provide information for "2024.07" in `Enter Year and Month (YYYY.MM)` followed by `Enter TAG:` which is equivalent to  `7572` in above example
2. This will auto-update the corresponding fields in **Apptainer.def** under `%arguments`, add the tag to `curl --silent -o ${APPTAINER_ROOTFS}/ApsimSetup.deb https://builds.apsim.info/api/nextgen/download/${TAG}/Linux` and complete the `%setup` on the same def file
3. Then it will ask `Would you like to submit the container build Slurm job? (Yes/No):` which we recommend answering `Yes`as it will auto update the `export APSIM_VERSION=` and   `export CACHETMPDIR=` based on the cluster of choice

#### Path to new container image. 

We are using  a relative path as defined in `build-container.def`

```bash
13	export IMAGE_PATH="../../apsim-simulations/container/"
```
<center>
[apptainer-build.webm](https://github.com/user-attachments/assets/a342fcd4-55e9-4615-896b-7eac46368e84)
</center>