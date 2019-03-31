#!/usr/bin/env bash

# Assuming you have a master and develop branch, and that you make a
# revert at the version they correspond to, e.g. v1.0.3
# Usage: ./revert.sh v1.0.3

# Get version argument and verify
version=$1
if [ -z "$version" ]; then
  echo "Please specify a version"
  exit
fi

versionLabel=v$version

# establish branch and tag name variables
devBranch=develop
masterBranch=master
releaseBranch=release-$versionLabel

# Output
echo "Revert release version $version"
echo "-------------------------------------------------------------------------"


# Success
echo "-------------------------------------------------------------------------"
echo "Revert release $version complete"