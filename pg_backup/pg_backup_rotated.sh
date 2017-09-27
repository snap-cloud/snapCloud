#!/bin/bash

###########################
####### LOAD CONFIG #######
###########################

while [ $# -gt 0 ]; do
    case $1 in
        -c)
            CONFIG_FILE_PATH="$2"
            shift 2
            ;;
        *)
            ${ECHO} "Unknown Option \"$1\"" 1>&2
            exit 2
            ;;
    esac
done

if [ -z $CONFIG_FILE_PATH ] ; then
    SCRIPTPATH=$(cd ${0%/*} && pwd -P)
    CONFIG_FILE_PATH="${SCRIPTPATH}/pg_backup.config"
fi

if [ ! -r ${CONFIG_FILE_PATH} ] ; then
    echo "Could not load config file from ${CONFIG_FILE_PATH}" 1>&2
    exit 1
fi

source "${CONFIG_FILE_PATH}"

###########################
#### PRE-BACKUP CHECKS ####
###########################

# Make sure we're running as the required backup user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ] ; then
    echo "This script must be run as $BACKUP_USER. Exiting." 1>&2
    exit 1
fi


###########################
### INITIALISE DEFAULTS ###
###########################

if [ ! $HOSTNAME ]; then
    HOSTNAME="localhost"
fi;

if [ ! $USERNAME ]; then
    USERNAME="postgres"
fi;


###########################
#### START THE BACKUPS ####
###########################

function perform_backups()
{
    SUFFIX=$1
    FINAL_BACKUP_DIR=$BACKUP_DIR"`date +\%Y-\%m-\%d`$SUFFIX/"

    echo "Making backup directory in $FINAL_BACKUP_DIR"

    if ! mkdir -p $FINAL_BACKUP_DIR; then
        echo "Cannot create backup directory in $FINAL_BACKUP_DIR. Go and fix it!" 1>&2
        exit 1;
    fi;

    #######################
    ### GLOBALS BACKUPS ###
    #######################

    echo -e "\n\nPerforming globals backup"
    echo -e "--------------------------------------------\n"

