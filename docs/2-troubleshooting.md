# Troubleshooting

## Creating a new Snakemake profile


!!! screwdriver-wrench "Create a new Snakemake profile with cookiecutter"

    * Load a `snakemake` module Or make sure `snakemake` in `$PATH`


    1. If not already, create a configuration directory for Snakemake profiles:
    
        ```bash
        profile_dir="${HOME}/.config/snakemake"
        mkdir -p "$profile_dir"
        ```
    
    2.  Use `cookiecutter` to create the Slurm profile template:
        - If `cookiecutter` isn't installed, load snakemake module and run `pip install --user cookiecutter`
            ```bash
            template="gh:Snakemake-Profiles/slurm"
            cookiecutter --output-dir "$profile_dir" "$template"
            ```
    
    3. During the cookiecutter process, you'll be prompted to set values for your profile. For example:
        ```bash
        profile_name [slurm]: myprofile
        sbatch_defaults []: account=my_account no-requeue exclusive
        cluster_sidecar_help: [Use cluster sidecar. NB! Requires snakemake >= 7.0! Enter to continue...]
        Select cluster_sidecar:
        1 - yes
        2 - no
        Choose from 1, 2 :
        cluster_name []:
        ```
    4. After completing the prompts, the profile scripts and configuration file will be installed in the $profile_dir ( `~/.config/snakemake`).
    
    5. You can then use this profile when running Snakemake by calling it via  `--profile` flag:
    
        ```python
        snakemake --profile myprofile ...
        ``
        
# A change for demo`

some text for demo

1. ...
2. ...