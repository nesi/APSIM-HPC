<center>
# APSIM-HPC
</center>

Deploy APSIM (Agricultural Production Systems sIMulator - https://www.apsim.info/) on high performance computing clusters.

<center>
![image](./images/overall.png)
</center>

## 1. Apptainer build


!!! terminal-2 "Building the APSIM container"

    ```bash
    git clone https://github.com/nesi/APSIM-HPC.git
    cd APSIM-HPC/01-apptainer-build
    ./updateversion-and-build.sh
    ```
    ??? video "`./updateversion-and-build.sh`"

        <video width="100%" controls>
          <source src="https://github.com/user-attachments/assets/a342fcd4-55e9-4615-896b-7eac46368e84" type="video/mp4">
          Your browser does not support the video tag.
        </video>


<br>
!!! note ""

## 2. Setup the working directory 


!!! circle-info "Structure/Content of the working directory"

    APSIM requires Weather files ( .met), Template to create the config files, CSV files with soil,file,database names and soil library .apsimx files to be on the same working directory.

    ```bash
    ├── 1.met
    ├── 2.met
    ├── 3.met
    ├── another_soilapsim_library.apsimx
    ├── ExampleConfigTemplate.txt
    ├── fileanddbnames.csv
    ├── my_master_soilapsim_library.apsimx
    └── soilnames.csv
    ```
<br>
!!! note ""

## 3. Update Workflow files for current simulation

!!! quote ""
    Please make sure to edit the files within the cloned repository without changing the directory structure or filenames. Final submission script relies on the existing structure and names to populate the working directory with runtime scripts.

!!! r-project "update `03-generate-config-files/generate_apsim_configs.R`"

    First file to be edited is `03-generate-config-files/generate_apsim_configs.R` which will be used to generate the config.txt files

    * Review line number 6, 8 and 11 

    ```r
    6 SoilNames <- as.vector(unlist(read.csv("soilnames.csv"))) ##List of soil names that must exist in the Soil Library .apsimx file (most likely supplied by experienced APSIM user)

    8 ConfigTemplate <- "ExampleConfigTemplate.txt" ##Base config file

    11 SoilLibrary <- "my_master_soilapsim_library.apsimx" ###Change name to the soil library you are using
    ```


!!! snake "update `08-snakemake/Snakefile_1`"

    * All changes are within the `config` block
        - `apptainer_bind` - We recommend binding the full filesystem. 
            - For **eRI**, It will be `"apptainer_bind": "/agr/scratch,/agr/persist"`
            - For **Mahuika**, it's `"apptainer_bind": "/nesi/project,/nesi/nobackup,/opt/nesi"`
        - `"excluded_txt_files"` is the name of the template config which will excluded during the processing. Otherwise, it will create a .apsimx and a place holder .db file for itself

    ```bash
       4 config = {
       5     "apptainer_bind": "/full/filesystem",
       6     "apptainer_image": "/path/to/container/image/version.aimg",
       7     "excluded_txt_files": ["ExampleConfigTemplate.txt"],
       8     "max_consecutive_failures": 10,
       9     "slurm_logdir": "slurmlogs"
      10 }
    ```
!!! snake "update `08-snakemake/Snakefile_2`"

    * Simlar to above, all changes are within the `config` block
        - `"excluded_apsimx_files"` is/are the name/s of the soil library .apsimx files which will excluded during the processing. Otherwise, it will create a .db file/s for those


    ```bash
       5 config = {
       6     "apptainer_bind": "/full/filesystem",
       7     "apptainer_image": "/path/to/container/image/version.aimg",
       8     "excluded_apsimx_files": ["my_master_soilapsim_library.apsimx", "another_soilapsim_library.apsimx"],
       9     "slurm_logdir": "slurmlogs",
      10     "size_threshold": 1 * 1024 * 1024  # 1MB in bytes
      11 }
    ```
<br>
!!! note ""

## 4. Submit the workflow to Scheduler

!!! bulb "Assumptions and pre-requisites"

    1. Cloned the latest version of the repo (https://github.com/nesi/APSIM-HPC.git)
    2. `03-generate-config-files/generate_apsim_configs.R` , `08-snakemake/Snakefile_1` and `08-snakemake/Snakefile_2` were updated with names of the template files,etc. 
    3. Filenames and directory structure **were/was not** altered. 

    
!!! rocket "Launch it with `source submit.sh`"

    What does it do : 
    
    <center>![image](./images/workflow.png){width="500"}</center>