#!/bin/ksh
## CHK_BKUP.ksh | June 15, 2017 | Version 1 | M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: Confirms X amount of backups are on disk and that at least one is less than X days old.
##          E-mail an alert if failure.
##
## Execution notes:
## Make sure to swap out "@NumberOfBackupsToRetain@" and "@MaximumAgeOfBackup@" with the proper numerical value
## for backup retention and age. "@BackupDirectory@" will be a directory housing backups. "@EmailAddressToNotify@"
## should have a valid e-mail address (with multiple addresses separate with a comma).
##
## This also assumes your backup string begins with the DB name and ends in 001. Script may need to be adjusted
## for multiple part backups.
##
## The script only checks the specified directory, it will not check sub-directories. You should be able to 
## adjust the "maxdepth" parameter to compensate. However, this is untested.
##
## Usage: ./CHK_BKUP.ksh <dbname> 
##


## Variable List and Assignment
DBNAME=$1
SERVER=`hostname`
NUM_RETAIN=@NumberOfBackupsToRetain@
DAYS_OLD=@MaximumAgeOfBackup@
BACKUP_DIR=@BackupDirectory@
MAIL_RECIP=@EmailAddressToNotify@

## Confirm we have a newer backup and that we have multiple backup files held locally.
FILECOUNT=$(find $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001" | wc -l)
DAYCOUNT=$(find $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001" -mtime -$DAYS_OLD | wc -l)

if [[ $FILECOUNT -lt $NUM_RETAIN || $DAYCOUNT -lt 1 ]];
then
  echo "Backups for $DBNAME on $SERVER are either older than $DAYS_OLD days or there are less than $NUM_RETAIN local backups." | mail -s "Backup Violation - $DBNAME" $MAIL_RECIP
fi