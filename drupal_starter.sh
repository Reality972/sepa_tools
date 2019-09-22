#!/usr/bin/env bash

#################################################################
# Complete build script for Drupal 8 projects
# Author: BNP real estate
#################################################################

# check bash version
if [ "${BASH_VERSION:0:1}" = "3" ]
then
    echo "--- ERROR: Please upgrade your Bash version to 4.x. Current is: $BASH_VERSION ---"
    exit 1
fi

# check environment
# todo: check composer, nodejs, php version, drush, sass, compass

# wizard
if [ "$1" = "-help" ] || [ "$1" = "--help" ]
then
    echo "----------------------------------------------------------"
    echo "Welcome in build wizard! Please setup your project:"
    echo ""

    #################################################################
    # variables from user input
    #################################################################

    read -p 'Init installation from GIT? (FALSE): ' PROJECT_INIT
    read -p 'Environment (STAGE/PROD): ' ENVIRONMENT
    read -p 'Project path: (absolute path, default is actual)' PROJECT_PATH
    read -p 'GIT repository name (origin): ' GIT_REPOSITORY
    read -p 'GIT branche name (master): ' GIT_BRANCH
    read -p 'Update composer? (yes)' COMPOSER_UPDATE
    read -p 'Backup database? (yes)' DB_BACKUP
    read -p 'Theme name?' THEME_NAME
    echo "----------------------------------------------------------"

else

    # recording params in format (-KEY=value)
    args=("$@")

    # todo: create assoc array (key=>value)
    declare -A params
    while [[ $# -gt 1 ]]
    do
        wSlash="$1"
        key="${wSlash/-}"
        params["$key"]="$2"
        shift
        shift
    done

    for i in "${!params[@]}"
    do
        key=$i
        value=${params[$i]}
        echo "$key : $value"
    done
fi


#################################################################
# variables empty input fix - default values
#################################################################

if [ -z "${PROJECT_INIT}" ]; then
    PROJECT_INIT=no
fi

if [ -z "${PROJECT_PATH}" ]; then
    PROJECT_PATH=$(pwd)
fi

if [ -z "${COMPOSER_UPDATE}" ]; then
    COMPOSER_UPDATE=no
fi

if [ -z "${DB_BACKUP}" ]; then
    DB_BACKUP=yes
fi

#################################################################
# relative paths to files and folders in project folder
#################################################################

THEME_PATH="../src/themes/custom"
DEVELOPMENT_SERVICES="../src/web/sites/development.services.yml"
SETTINGS_PROD="../src/web/sites/default/settings.production.php"
SETTINGS_LOCAL="../src/web/sites/default/settings.local.php"
CONFIG_FOLDER=$(find ../src/web/sites/default -name \*config_\* -type d -maxdepth 1 -print | head -n1)
BACKUP_BUILD=$(date +%Y-%m-%d-%T)
BACKUP_FOLDER="_BACKUP_BEFORE_BUILD/${BACKUP_BUILD}"
ENVIRONMENT="PROD"


#################################################################
#               Check parameters
#################################################################

if [ "${ENVIRONMENT}" = "PROD" ]
then

    if [ ! -d "${PROJECT_PATH}" ]
    then
        echo "--- ERROR: Please set -ENV as valid path (/path/to/project_root_folder), but not docroot! ---"
        exit 1
    else
        echo "--- BUILD environment setup to: ${ENVIRONMENT}, path: ${PROJECT_PATH} ---"
    fi

else
    echo "--- ERROR: Please set -ENV parameter (PROD/STAGE) ---"
    exit 1
fi

#################################################################
#               Check real status of environment
#################################################################

if [ !-d "vendor" ]
then

    echo "--- Alert: vendor directory not exist or is empty, installation started! ---"

    # run install
    composer install

    # disable composer update
    COMPOSER_UPDATE=no
fi

# run process
echo "--- Switching to project folder... ---"
cd "${PROJECT_PATH}"

#################################################################
#               Backup database and configs
#################################################################

mkdir BACKUP_FOLDER
zip -r "${BACKUP_FOLDER}/configs.zip" "${CONFIG_FOLDER}"
echo ""

if [ "${DB_BACKUP}" = "yes" ]
then
    drush sql-dump > "${BACKUP_FOLDER}/db.sql" --root=docroot
fi

echo "--- Info: Backups are stored in: ${BACKUP_FOLDER} ---"
echo ""

#################################################################
#               Maintenance ON
#################################################################

echo "--- Maintenance turning ON... ---"
drush sset system.maintenance_mode --root=docroot

#################################################################
#               GIT update
#################################################################

if [ ! -z "${GIT_REPOSITORY}" && ! -z "${GIT_BRANCH}" ]
then
    git fetch --all
    git pull "${GIT_REPOSITORY}"
    git reset --hard "${GIT_REPOSITORY}"/"${GIT_BRANCH}"
else
    echo "--- Alert: Skipping GIT update, parameters was empty ---"
    exit 1
fi

#################################################################
#               Composer update / install
#################################################################

if [ "yes" == "${COMPOSER_UPDATE}" ]
then
    composer update
fi

#################################################################
#               Configuration sync
#################################################################

echo "--- Clearing drush caches ... ---"
drush cr drush --root=docroot
echo ""

#################################################################
#               Configuration sync, Database update
#################################################################

echo "--- Importing configuration ... ---"
echo ""
if [ -d "${SETTINGS_PROD}" ] || [ -d "${SETTINGS_LOCAL}" ]
then
    drush config-import -y --root=docroot
    echo ""
else
    echo "--- ERROR: Settings file missing! ---"
    exit 1
fi

echo "--- Starting database updates. ---"
drush updb -y --root=docroot
echo ""

echo "--- Clearing caches ---"
drush cr --root=docroot
echo ""

#################################################################
#               Start theme stuffs
#################################################################

echo "--- Switching to theme folder ... ---", # todo: test it
cd "${THEME_PATH}/${THEME_NAME}"
echo ""

#################################################################
#               NodeJS modules install / update
#################################################################

if [ -d "node_modules" ]
then
    echo "--- Updating npm modules ... ---"
    npm update
else
    echo "--- Installing npm modules ... ---"
    npm install
fi
echo ""

#################################################################
#               Bower
#################################################################

echo "--- Updating bower libs .. ---."
bower update --allow-root
echo ""

#################################################################
#               SASS
#################################################################

echo "--- Compiling SASS to CSS ... ---"
rm css/"${THEME_NAME}"-global.css # todo: test it
compass compile --trace
echo ""

#################################################################
#               Delete localhost environment stuffs
#################################################################

# if we have production => delete development stuffs
if [ "${ENVIRONMENT}" == "PROD" && -d "${DEVELOPMENT_SERVICES}" &&  -d "${SETTINGS_LOCAL}" ]
then
    echo "--- Switch to project root folder ---"
    cd ../../../../
    echo ""
    echo "--- Removing development.services.yml, settings.local.php ---"
    rm "${DEVELOPMENT_SERVICES}"
    rm "${SETTINGS_LOCAL}"
    echo ""

    # todo: disable webprofiler module, devel
fi

#################################################################
#               Maintenance OFF
#################################################################

echo "--- Maintenance turning OFF ... ---"
drush sset system.maintenance_mode 0 --root=docroot
echo ""

echo "--- BUILD END - PROBABLY SUCCESSFUL ---"