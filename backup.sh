#!/usr/bin/env bash

set -e

# Assuming you have a master and develop branch, and that you make new
# release branches named as the version they correspond to, e.g. 1.0.3
# Usage: ./release.sh 1.0.3

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

# USE FULL PATH
BACKUP_DIR="./db-backups/"
DRUPAL_DIR="C:/Bitnami/wappstack-7.1.25-0/apache2/htdocs/clo/"
BACKUP_NAME="clickandown"
MAXDAYS=5

# External email address to send monthly encrypted backup files to
EXTERNAL_EMAIL="you@yourexternalemail.com"
 
# redirect errors and output to log file
exec 2>&1 1>>"${BACKUP_DIR}backup-log.txt"
 
NOW=$(date +"%Y-%m-%d")
 
echo -e "${CYAN}----------------------------------------------------------${SET}"
echo -e "${CYAN}-               Generate Backup BDD - $NOW               -${SET}"
echo -e "${CYAN}----------------------------------------------------------${SET}"

# Switch to the docroot.
cd ${DRUPAL_DIR}

# Backup the database.
echo -e "${CYAN}Backup the database${SET}"
echo -e "${CYAN}----------------------------------------------------------${SET}"
drush sql-dump --gzip --result-file=${BACKUP_DIR}${BACKUP_NAME}-`date +%F-%T`.sql

# Delete local database backups older than $MAXDAYS days.
echo -e "${CYAN}Delete local database backups older than $MAXDAYS days${SET}"
echo -e "${CYAN}----------------------------------------------------------${SET}"
find ${BACKUP_DIR} -type f -name "*.sql.gz" -mtime +${MAXDAYS} -delete

# Success
echo -e "${CYAN}----------------------------------------------------------${SET}"
echo -e "\n\t- Backup complete ${GREEN}[OK]${SET}"