#!/usr/bin/env python3

import os
import re

def natural_sort_key(s):
    return [int(c) if c.isdigit() else c.lower() for c in re.split(r'(\d+)', s)]

def update_main_readme(repo_path):
    # Get all subdirectories
    subdirs = [d for d in os.listdir(repo_path) if os.path.isdir(os.path.join(repo_path, d))]
    
    # Sort subdirectories based on their leading number
    subdirs.sort(key=natural_sort_key)
    
    consolidated_content = []
    
    # Read the content of each numbered README.md
    for subdir in subdirs:
        readme_path = os.path.join(repo_path, subdir, 'README.md')
        if os.path.exists(readme_path):
            with open(readme_path, 'r') as f:
                content = f.read()
                consolidated_content.append(f"\n\n# {subdir}\n\n{content}")
    
    # Read the existing content of the main README.md
    main_readme_path = os.path.join(repo_path, 'README.md')
    existing_content = ""
    if os.path.exists(main_readme_path):
        with open(main_readme_path, 'r') as f:
            existing_content = f.read()
    
    # Append the consolidated content to the existing content
    full_content = existing_content + ''.join(consolidated_content)
    
    # Write the full content back to the main README.md
    with open(main_readme_path, 'w') as f:
        f.write(full_content)

# Usage
repo_path = './'
update_main_readme(repo_path)