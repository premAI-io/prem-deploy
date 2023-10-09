#!/bin/bash

# Record the start time
START_TIME=$(date +%s)

# Change to the prem-gateway directory
cd prem-gateway || exit 1  # exit if change directory fails

# Run the command
sudo make runall PREMD_IMAGE=prem-daemon_local PREMAPP_IMAGE=prem-app_local

# Record the end time
END_TIME=$(date +%s)

# Calculate the duration
DURATION=$((END_TIME - START_TIME))

# Display the duration
echo "Script executed in $DURATION seconds."