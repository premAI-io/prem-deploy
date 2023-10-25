#!/bin/bash

set -e

PREMAI_IO_USER="premAI-io"

# Ensure the correct number of arguments are provided
if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 USER REPO BRANCH"
    exit 1
fi

USER=$1
REPO=$2
BRANCH=$3
echo "USER: $USER"
echo "REPO: $REPO"
echo "BRANCH: $BRANCH"

# There are 3 repositories and there can be multiple users who forked any of these
# 3 repositories. The script should work for all the combinations of these 3
# repositories and multiple users who forked them.
# Lets say USER A want to run prem-app from his forked repo, and prem-daemon from
# someone else's forked repo, and prem-gateway from prem-ai-io repo.
# By default script will checkout main branch for all the 3 repos for $PREMAI_IO_USER
# Beside that, if $USER is different from $PREMAI_IO_USER, script will add $USER as
# a remote, fetch $USER and checkout $BRANCH and pull latest changes.

# Assumption is that prem-app, prem-daemon, prem-gateway are open source repos
# and that the user has forked them
# 1. Check if the repo exists in the current directory
# 2. If repo doesnt exist, clone the $PREMAI_IO_USER repo's main branch
# 3. If $USER is different from $PREMAI_IO_USER, add $USER as a remote, fetch
# $USER and checkout $BRANCH
# 4. If $USER is same as $PREMAI_IO_USER and $BRANCH is not main, checkout $BRANCH
# 5. If $USER is same as $PREMAI_IO_USER and $BRANCH is main, pull latest changes
# from $PREMAI_IO_USER main branch
# 6. If repo exists, check if the current branch is same as $BRANCH and remote is
# same as $USER, if yes, pull latest changes, if no, checkout $BRANCH and pull
# latest changes

# 1st use case, $USER is same as $PREMAI_IO_USER and $BRANCH is main no repo exists
# 2nd use case, $USER is same as $PREMAI_IO_USER and $BRANCH is main repo exists
# 3rd use case, $USER is same as $PREMAI_IO_USER and $BRANCH is not main repo exists
# 4th use case, $USER is different from $PREMAI_IO_USER and $BRANCH is main repo exists
# 5th use case, $USER is different from $PREMAI_IO_USER and $BRANCH is not main repo exists


# Check if folder exists
if [[ ! -d "$REPO" ]]; then
    # If not, create it, cd into it, and clone the repo
    echo "Cloning $REPO..."
    git clone https://github.com/$PREMAI_IO_USER/"$REPO".git
    cd "$REPO"
else
    # If it does, cd into it
    cd "$REPO"
fi

 # Check if $USER is the same as $PREMAI_IO_USER
 if [ "$USER" == "$PREMAI_IO_USER" ]; then
     echo "User is $PREMAI_IO_USER"
     # If $BRANCH is main, pull the latest changes
     if [ "$BRANCH" == "main" ]; then
         echo "Branch is main"
         git checkout main
         git pull --no-edit origin main
     else
         echo "Branch is not main"
         git fetch origin
         # Check if the branch exists on the remote
         if git branch -r | grep -q "origin/$BRANCH"; then
             echo "Checking out $BRANCH"
             # Check if the branch exists locally
             if git branch | grep -q "$BRANCH"; then
                 git checkout "$BRANCH"
             else
                 git checkout --track "origin/$BRANCH"
             fi
             git pull --no-edit origin "$BRANCH"
         else
             echo "Error: Branch $BRANCH does not exist on the remote."
             exit 1
         fi
     fi
 else
     # If $USER is different from $PREMAI_IO_USER
     # Check if the remote for $USER already exists
     if ! git remote | grep -q "$USER"; then
         echo "User is not $PREMAI_IO_USER"
         # If not, add $USER as a remote
         git remote add "$USER" https://github.com/"$USER"/"$REPO".git
     fi
     git fetch "$USER"
     # Checkout to $BRANCH and pull the latest changes
     git checkout -- "$BRANCH"
     git pull --no-edit "$USER" "$BRANCH"
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