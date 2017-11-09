#!/bin/ksh
## PRIM_BKUP_DEL.ksh | Oct 25, 2017 | Version 1 | M. Krafick | No warranty implied, use at your own risk.
##
## Purpose:
##   Secondary script used in conjunction with ROLL_BACKUPS.ksh on a primary server.
##   Called remotely by ROLL_BACKUPS.ksh to prune redundant backups SCP'ed to this server for offsite retention.
##
## Pre-requisite:
##   ROLL_BACKUPS.ksh installed on a primary database server.
##
## Misc Notes:
##   - Make sure to swap out "@VALUE@" in the "Variable List and Assignment" section.
##   - This assumes your backup string begins with the DB name and ends in 001.
##   - Script is not designed for multiple part backups or DPF.
##   - Any assessment or count of "what is in my directory" is not recursive. "Find" is set for that specific filseystem
##     and will not scan subfolders. To alter, adjust the "-maxdepth" flag in each "find" command.
##   - Trusted login between servers must be configured for this to be called remotely
##
## Usage: ./PRIM_BKUP_DEL.ksh <dbname>

##### Variable Definitions #####
# DBNAME							- Database backups should be archived for. Passed at command line call.
# NOW									- Calculates date/time of script run to be used as a timestamp on logs.
# BACKUP_DIR					- Directory SCP'ed redundant backup (from primary server) resides in now.
# OUTPUT_DIR					- Directory that will contain log file from script execution.
# CURRENT_RETENTION		- Number days to keep redundant backups.
# MAIL_RECIP					- E-mail list, seperated by commas, that receive an alert of script fails.



##### Variable List and Assignment #####
DBNAME=$1
NOW=`date '+%Y%m%d%H%M%S'`
BACKUP_DIR=@VALUE@
BACKUP_ARCH=@VALUE@
OUTPUT_DIR=@VALUE@
CURRENT_RETENTION=@VALUE@
MAIL_RECIP=@VALUE@



##### CREATE HEADER OF SCRIPT LOG FILE #####
echo "" >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log
echo "# # # # Starting Backup Pruning for STANDBY - `date` # # # #" >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log



###### PRUNE ARCHIVED BACKUPS IF THEY EXCEED RETENTION POLICY #####
DEL_COUNT=`find  $BACKUP_DIR -maxdepth 1 -mtime +$CURRENT_RETENTION -name "$DBNAME*001"| wc -l`

if [[ $DEL_COUNT -gt 0 ]]
 then
  echo "Latest PRIMARY backup(s) to be purged from STANDBY:" >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log
  find $BACKUP_DIR -maxdepth 1 -mtime +$CURRENT_RETENTION -name "$DBNAME*001"| awk -F'/' '{print $NF}' | while read STNDBY_BKUP_PURGE
  do
   echo "   $BACKUP_DIR/$STNDBY_BKUP_PURGE" >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log
   rm $BACKUP_DIR/$STNDBY_BKUP_PURGE
        if [ $? != 0 ]; then
         echo "Warning: Unable to delete backups on STANDBY. Possible permission issue. Dir: $BACKUP_DIR, Server: `hostname`" | mail -s "Backup Archive Warning - $DBNAME" $MAIL_RECIP
         echo "Unable to delete backups from backup directory on STANDBY. Possible permission issue." >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log
         exit 1
        fi
  done
 else
  echo "There are no backup files older than retention requirements. No PRIMARY to STANDBY backups purged." >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log
fi

## Clean up old log files
echo "Cleaning up old log files ..." >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log
find $OUTPUT_DIR -name "STNDBY_BKUP_DEL.$DBNAME.*.log" -mtime +30 -exec rm {} \;


##### CREATE FOOTER FOR SCRIPT LOG FILE #####
echo "# # # # Script Complete - `date` # # # #" >> $OUTPUT_DIR/STNDBY_BKUP_DEL.$DBNAME.$NOW.log