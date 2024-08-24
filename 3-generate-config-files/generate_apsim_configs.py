#!/usr/bin/env python3

import os
import itertools
import csv

def generate_config_files(soil_names_file, weather_dir, base_config_file, output_dir):
    # Read soil names from the CSV file
    with open(soil_names_file, 'r') as f:
        soil_names = [line.strip() for line in f if line.strip()]

    # Get weather files
    weather_files = [f.split('.')[0] for f in os.listdir(weather_dir) if f.endswith('.met')]

    # Read base config
    with open(base_config_file, 'r') as f:
        base_config = f.read()

    # Generate configurations
    for soil_name, weather_file in itertools.product(soil_names, weather_files):
        # Replace placeholders in the config
        config = base_config.replace('WeatherFilename', weather_file)
        config = config.replace('SoilName', soil_name)

        # Generate output filename
        output_filename = f"{weather_file}_{soil_name}.txt"
        output_path = os.path.join(output_dir, output_filename)

        # Write the config file
        with open(output_path, 'w') as f:
            f.write(config)

        print(f"Generated config file: {output_filename}")

# Usage
generate_config_files(
    soil_names_file='SubsetSoilName.csv',
    weather_dir='Weather',
    base_config_file='ExampleConfig.txt',
    output_dir='ConfigFiles'
)
