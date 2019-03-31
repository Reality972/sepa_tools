#!/bin/bash
# while-menu: a menu driven system information program

DARKGRAY='\033[1;30m'
RED='\033[0;31m'
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
SET='\033[0m'

DELAY=4 # Number of seconds to display results

#Actions to take based on selection
function BUILDRELEASE {
    echo -e "${CYAN}----------------------------------------------------------${SET}"
    echo -e "${CYAN}-               Generate Release                         -${SET}"
    echo -e "${CYAN}----------------------------------------------------------${SET}"

    # establish branch and tag name variables
    devBranch=develop

    # current Git branch
    branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

    # current project name
    projectName=$(git config --local remote.origin.url|sed -n 's#.*/\([^.]*\)\.git#\1#p')

    # establish master branch name variables
    masterBranch=$branch

    # Ensure working directory in version branch clean
    git update-index -q --refresh
    if ! git diff-index --quiet HEAD --; then
        echo -e "\n\t- Working directory not clean, please commit your changes first ${RED}[KO]${SET}"
        exit
    fi

    # checkout to master branch, this will break if the user has uncommited changes
    git checkout $masterBranch

    # master branch validation
    if [ $branch = "master" ]; then
        echo -e "${GREEN}Enter the release version number: ${SET}"

        read versionNumber

        # v1.0.0, v1.7.8, etc..
        versionLabel=v$versionNumber

        # establish branch and tag name variables
        releaseBranch=$versionNumber
        tagName=$versionLabel

        echo -e "${GREEN}Merge develop to master${SET}"
        git merge --no-ff $devBranch

        echo -e "${GREEN}Started releasing ${YELLOW}$versionLabel${SET} for ${YELLOW}$projectName${SET} .....${SET}"
   
        # pull the latest version of the code from master
        git pull

        # create empty commit from master branch
        git commit --allow-empty -m "Creating Branch $releaseBranch"

        # create tag for new version from -master
        git tag $tagName

        # push commit to remote origin
        git push

        # push tag to remote origin
        git push --tags origin 
        
        # create the release branch from the -master branch
        git checkout -b $releaseBranch $masterBranch

        # push local releaseBranch to remote
        git push -u origin $releaseBranch

        echo "$versionLabel is successfully released for $projectName ...."
        echo "Checking out into $masterBranch again, where it all started...... :)"

        # checkout to master branch
        git checkout $masterBranch

        # pull the latest version of the code from master
        git pull

        echo "Enter new version number for $projectName"	
        read newVersionNumer

        # Update Maven version to next release number
        #mvn versions:set -DnewVersion=$newVersionNumer -DgenerateBackupPoms=false
        
        # Commit setting new master branch version	
        git commit -a -m "Setting master branch version to $newVersionNumer"

        # push commit to remote origin
        git push
        
        echo "Maven POM File Version is set to new version $newVersionNumer"	
        echo "Bye!"
    else 
        echo "Please make sure you are on master branch and come back!"
        echo "Bye!"
    fi
}

function CLEANBRANCH {
    echo -e "${CYAN}----------------------------------------------------------${SET}"
    echo -e "${CYAN}-               Clean local branches                     -${SET}"
    echo -e "${CYAN}----------------------------------------------------------${SET}"

    # Prune remote branches
    git remote prune origin 

    # List local git branches
    # Filter git branches down to only those with deleted upstream/remote counterparts
    # Pluck out branch names from output
    # Delete the branches
    git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -d  
}

while [[ $REPLY != 0 ]]; do
    clear
	echo -e "${CYAN}
    Please Select:
        1. Clean local branch Git with remote branch
        2. Start new branch
        3. Display Home Space Utilization
        4. Make a release version
        0. Quit${SET}"

    read -p "Enter selection : "

    if [[ $REPLY =~ ^[0-4]$ ]]; then
        # Clean local
        if [[ $REPLY == 1 ]]; then
            CLEANBRANCH
            sleep $DELAY
        fi
        # Start branch
        if [[ $REPLY == 2 ]]; then
            df -h
            sleep $DELAY
        fi

        if [[ $REPLY == 3 ]]; then
            if [[ $(id -u) -eq 0 ]]; then
                echo "Home Space Utilization (All Users)"
                du -sh /home/*
            else
                echo "Home Space Utilization ($USER)"
                du -sh $HOME
            fi
            sleep $DELAY
        fi

        if [[ $REPLY == 4 ]]; then
            BUILDRELEASE
            sleep $DELAY
        fi
    else
        echo "Invalid entry."
        sleep $DELAY
    fi
done
echo "Program terminated."