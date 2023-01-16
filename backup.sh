#!/bin/bash

# this script is originally from https://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync/
# https://gist.github.com/brandonb927/3195465

set -e # break on error

cd ~
pwd

# mkdir sure .backup_logs dir exists
mkdir -p .backup_logs
cd .backup_logs

# Disc backup script
# Requires rsync 3

# Ask for the administrator password upfront
sudo -v

# IMPORTANT: Make sure you update the `DST` variable to match the name of the
# destination backup drive

DST="/Volumes/MacBackup/"
SRC="/System/Volumes/Data/"
EXCLUDE="/Users/qaq/.backupignore"

PROG=$0

# --acls                   update the destination ACLs to be the same as the source ACLs
# --archive                turn on archive mode (recursive copy + retain attributes)
# --delete                 delete any files that have been deleted locally
# --delete-excluded        delete any files (on DST) that are part of the list of excluded files
# --exclude-from           reference a list of files to exclude
# --hard-links             preserve hard-links
# --one-file-system        don't cross device boundaries (ignore mounted volumes)
# --sparse                 handle sparse files efficiently
# --verbose                increase verbosity
# --xattrs                 update the remote extended attributes to be the same as the local ones

if [ ! -r "$SRC" ]; then
    logger -t $PROG "Source $SRC not readable - Cannot start the sync process"
    exit;
fi

if [ ! -w "$DST" ]; then
    logger -t $PROG "Destination $DST not writeable - Cannot start the sync process"
    exit;
fi

echo "Excluding from $EXCLUDE"
cat $EXCLUDE

BEGIN_DATE=$(date +%s)

logger -t $PROG "Start rsync"

# sleep 3

# store stdout and stderr to backup-$(date +%Y-%m-%d).log
# store stderr to backup-$(date +%Y-%m-%d).error.log

exec > >(tee -a backup-$(date +%Y-%m-%d).log)
exec 2> >(tee -a backup-$(date +%Y-%m-%d).error.log >&2)

sudo /opt/homebrew/bin/rsync \
    --acls \
    --archive \
    --delete \
    --delete-excluded \
    --exclude-from=$EXCLUDE \
    --hard-links \
    --one-file-system \
    --sparse \
    --verbose \
    --xattrs \
    --ignore-errors \
    "$SRC" "$DST"

logger -t $PROG "End rsync"

END_DATE=$(date +%s)

osascript -e 'display notification "Backup completed in '"$(($END_DATE - $BEGIN_DATE))"' seconds" with title "Backup Script"'

printf "\n\n\n"
echo "========== Backup Errors =========="
cat backup-$(date +%Y-%m-%d).error.log
echo "==================================="

exit 0

