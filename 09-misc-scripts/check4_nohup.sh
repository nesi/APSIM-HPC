#!/bin/bash

username="<username>"

while true; do
    nohup_processes=$(ps -u $username | grep -v grep | grep nohup)
    if [ -z "$nohup_processes" ]; then
        echo "All nohup processes for $username have finished."
        break
    else
        echo "Nohup processes still running for $username:"
        echo "$nohup_processes"
        sleep 60  # Wait for 60 seconds before checking again
    fi
done