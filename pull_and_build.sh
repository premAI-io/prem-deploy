#!/bin/bash

set -e

# Ensure the correct number of arguments are provided
if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 USER REPO BRANCH"
    exit 1
fi

USER=$1
REPO=$2
BRANCH=$3

# Check if folder exists
if [[ ! -d "$REPO" ]]; then
    # If not, create it, cd into it, and clone the repo
    echo "Cloning $REPO..."
    mkdir "$REPO" && cd "$REPO"
    git clone "https://github.com/$USER/$REPO.git" --branch "$BRANCH" --single-branch .
else
    # If it does, cd into it
    cd "$REPO"

    # Get the name of the current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    # Get the URL of the 'origin' remote
    CURRENT_REMOTE_URL=$(git remote get-url origin)

    # Check if the current branch and remote URL match the passed arguments
    if [[ "$CURRENT_BRANCH" == "$BRANCH" && "$CURRENT_REMOTE_URL" == "https://github.com/$USER/$REPO.git" ]]; then
        echo "Pulling latest changes for $BRANCH..."
        # If so, just pull the latest changes
        git pull origin "$BRANCH"
    else
        # Attempt to checkout the specified branch
        git checkout "$BRANCH" 2> /dev/null

        # If checkout fails, add the new user as a remote and try again
        if [[ "$?" -ne 0 ]]; then
            echo "Adding $USER as a remote..."
            git remote add "$USER" "https://github.com/$USER/$REPO.git" 2> /dev/null || true # Ignore error if remote already exists
            git fetch "$USER"
            git checkout "$BRANCH"
        fi
    fi
fi

# Build the Docker image
# Check if REPO is "prem-gateway" to apply custom logic
if [[ "$REPO" == "prem-gateway" ]]; then
    # 1. cd to dns and run docker build
    cd dns && sudo docker build -t "${REPO}_dns_local" . && cd ..
    # 2. cd to controller and run docker build
    cd controller && sudo docker build -t "${REPO}_controller_local" . && cd ..
    # 3. cd to auth and run docker build
    cd auth && sudo docker build -t "${REPO}_auth_local" .
else
    sudo docker build -t "${REPO}_local" .
fi