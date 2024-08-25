### How to launch the apptainer build

1. Run `./updateversion-and-build.sh` and respond to prompts 
2. Once the image built was completed, execute "clean.sh"

#### What does the `updateversion-and-build.sh` do 

1. It will ask to define the APSIM Release information ( .deb version). Current release branch has the format of "2024.07.7572.0" and the prompts will request to provide information for "2024.07" in `Enter Year and Month (YYYY.MM)` followed by `Enter TAG:` which is equivalent to  `7572` in above example