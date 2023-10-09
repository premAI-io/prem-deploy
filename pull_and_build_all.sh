#!/bin/bash

set -e

# Set default user and branch values
DEFAULT_USER="premaI-io"
DEFAULT_BRANCH="main"

# Check for provided arguments and assign them or use default values
USER1=${1:-$DEFAULT_USER}
BRANCH1=${2:-$DEFAULT_BRANCH}
USER2=${3:-$DEFAULT_USER}
BRANCH2=${4:-$DEFAULT_BRANCH}
USER3=${5:-$DEFAULT_USER}
BRANCH3=${6:-$DEFAULT_BRANCH}

# Repo names are hardcoded
REPO1="prem-gateway"
REPO2="prem-app"
REPO3="prem-daemon"

# Run pull_and_build.sh script for each user/repo/branch combination
./pull_and_build.sh "$USER1" "$REPO1" "$BRANCH1"
./pull_and_build.sh "$USER2" "$REPO2" "$BRANCH2"
./pull_and_build.sh "$USER3" "$REPO3" "$BRANCH3"