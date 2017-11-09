#!/bin/ksh
## ROLL_BACKUPS.ksh | Oct 25, 2017 | Version 2 | M. Krafick | No warranty implied, use at your own risk.
##
## Purpose:
##   Archives backup files over X days old to an archive area on the same server. Keeps a minimum amt of backups "active". 
##   Optional section that will SCP backups to an offsite location for additional redundancy.
##
## Misc Notes:
##   - Make sure to swap out "@VALUE@" in the "Variable List and Assignment" section.
##   - This assumes your backup string begins with the DB name and ends in 001. 
##   - Script is not designed for multiple part backups or DPF.
##   - Any assessment or count of "what is in my directory" is not recursive. "Find" is set for that specific filseystem
#      and will not scan subfolders. To alter, adjust the "-maxdepth" flag in each "find" command.
##   - Optional: SCP abliity requires trusted login between servers with RSA Key.
##               Hostname of remote server must be in hosts file of primary server or referenced by IP directly.
##               For SCP file cleanup on STANDBY, PRIM_BKUP_DEL.ksh is required on remote target server.
##
## Work Flow:
##   1. Pull most recent backup taken and SCP to a STANDBY server for redundancy. (Optional)
##      1a. Second remote script called to prune redundant backups as needed, by age.
##   2. Current backup directory is assessed for oldest backup by defined age.
##   3. Oldest backup is moved from backup directory to an archive directory ON SAME SERVER.
##   4. Archive directory ON SAME SERVER is assessed for backups on a older defined age. 
##      If there are at least two "active" backups in main backup directory, prune oldest archived backup by defined age. 
##   5. Clean up script logs over 30 days.
##
## Usage: ./ROLL_BACKUP.ksh <dbname>

##### Variable Definitions #####
# DBNAME							- Database backups should be archived for. Passed at command line call.
# NOW									- Calculates date/time of script run to be used as a timestamp on logs.
# BACKUP_DIR					- Directory current backup resides in now. Backups used for immediate (last few days) recovery.
# BACKUP_ARCH					- Filesystem on same system that backups should be rolled off to.
# OUTPUT_DIR					- Directory that will contain log file from script execution.
# CURRENT_RETENTION		- Number days to keep backups in the primary backup directory.
# ARCHIVE_RETENTION		- Number of days backups that were rolled from primary directory will be held before permanent deletion.
# MAIL_RECIP					- E-mail list, seperated by commas, that receive an alert of script fails.
# REMOTE_TARGET				- Optional feature: Hostname of secondary server newer backups are SCP'ed to for redundancy.
# REMOTE_SCRIPTDI			- Optional feature: Remote server directory containing PRIM_BKUP_DEL.ksh (purge process on second server).
# REMOTE_BKUPDIR			- Optional feature: Remote server directory containing recent backups for redundancy.
# FTP_DAYS_OLD=2			- Optional feature: How recent (in days) my backup should be on primary for it should be SCP'ed to standby.



##### Variable List and Assignment #####
## Note: Optional feature variables are commented out.
DBNAME=$1
NOW=`date '+%Y%m%d%H%M%S'`
BACKUP_DIR=@VALUE@
BACKUP_ARCH=@VALUE@
OUTPUT_DIR=@VALUE@
CURRENT_RETENTION=@VALUE@
ARCHIVE_RETENTION=@VALUE@
MAIL_RECIP=@VALUE@
# REMOTE_TARGET=@VALUE@
# REMOTE_SCRIPTDIR=@VALUE@
# REMOTE_BKUPDIR=@VALUE@
# FTP_DAYS_OLD=@VALUE@


##### CREATE HEADER OF SCRIPT LOG FILE #####
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "# # # # Starting Backup Archive Process - `date` # # # #" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log



# ##### OPTIONAL: SCP TO STANDBY SERVER FOR REDUNDANCY #####
# ## This section will be commented out as it is not a default feature. Remove "##" to enable.
# 
# ## Assess (usually) which backup is most recent backup and sends offsite
# ## Note: This is a SCP command, so the system date assigned to the backup on standby is not backup date but timespamp of SCP command.
# 
# echo "Most recent backup(s) to be moved offsite for redundancy:" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
# find $BACKUP_DIR -maxdepth 1 -mtime -$FTP_DAYS_OLD -name "$DBNAME*001" | awk -F'/' '{print $NF}' >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
# 
# 
# find $BACKUP_DIR -maxdepth 1 -mtime -$FTP_DAYS_OLD -name "$DBNAME*001" | awk -F'/' '{print $NF}' | while read LATEST_FTP
# do
#  scp $BACKUP_DIR/$LATEST_FTP db2inst1@$REMOTE_TARGET:$REMOTE_BKUPDIR
#  if [ $? != 0 ]; then
#   echo "SCP Failed, possible lost connection or filesystem permission issue on STANDBY." >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
#   echo "Warning: SCP Failed, possible lost connection or filesystem permission issue on STANDBY. Archive process stopped. Partial backup will exist in $REMOTE_BKUPDIR on STANDBY database server  $REMOTE_TARGET" | mail -s "Backup Archive Warning - $DBNAME" $MAIL_RECIP
#   exit 1
#  fi
# done
# 
# ## Execute pruning of redundant backups on STANDBY.
# ## Note: Error checking with remote command is inconsistant, so failure notification will probably happen from remote server.
# ssh db2inst1@$REMOTE_TARGET "$REMOTE_SCRIPTDIR/PRIM_BKUP_DEL.ksh $DBNAME"
# if [ $? != 0 ]; then
#   echo "Unable to execute backup pruning on STANDBY database."  >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
#   echo "Warning: Unable to execute backup pruning script located in $REMOTE_SCRIPTDIR on STANDBY database server $REMOTE_TARGET." | mail -s "Backup Archive Warning - $DBNAME" $MAIL_RECIP
#   exit 1
# fi



##### ROLL BACKUP FROM ACTIVE DIRECTORY TO ARCHIVE DIRECTORY #####

## Display what currently exists in active and archive backup directories
CURRENT_RETENTION_COUNT=`find  $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001" | wc -l`
CURRENT_ARCHIVE_RETENTION=`find  $BACKUP_ARCH -maxdepth 1 -name "$DBNAME*001" | wc -l`

echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "(Before) Number of current backups in $BACKUP_DIR: $CURRENT_RETENTION_COUNT" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
find  $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001" | awk -F'/' '{print $NF}' >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "(Before) Number of current archived backups in $BACKUP_ARCH: $CURRENT_ARCHIVE_RETENTION" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
find  $BACKUP_ARCH -maxdepth 1 -name "$DBNAME*001"| awk -F'/' '{print $NF}' >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log


## Evaluate retention policy by defined age, move backup from main "active" backup directory to archive backup directory
echo "Evaluating retention policy - Current Backups Held: $CURRENT_RETENTION Days | Archive Backups Held: $ARCHIVE_RETENTION Days" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log

MOVE_COUNT=`find  $BACKUP_DIR -maxdepth 1 -mtime +$CURRENT_RETENTION -name "$DBNAME*001"| wc -l`

if [[ $MOVE_COUNT -gt 0 ]]
 then
  echo "Latest backup(s) to be moved from current to archive:" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
  find  $BACKUP_DIR -maxdepth 1 -mtime +$CURRENT_RETENTION -name "$DBNAME*001"| awk -F'/' '{print $NF}' | while read OLDEST_BACKUPS
  do
   if [ ! -f  $BACKUP_ARCH/$OLDEST_BACKUPS ];
   then
      echo "   $BACKUP_DIR/$OLDEST_BACKUPS" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
      mv $BACKUP_DIR/$OLDEST_BACKUPS $BACKUP_ARCH/.
      if [ $? != 0 ]; then
         echo "Moving current backups to archive failed. Check for paetial copies and capacity or permission issues." | mail -s "Backup Archive Warning - $DBNAME" $MAIL_RECIP
         echo "Aborting -- Moving current backups to archive failed. Check for partial copies and capacity or permission issues." >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
         exit 1
      fi
   fi
  done
  echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
fi


## FAILSAFE -- If there are less than 2 backups in "active" backup directory, do not purge, break out
FAILSAFE_COUNT=`find  $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001"| wc -l`
if [[ $FAILSAFE_COUNT -lt 2 ]]
 then
 echo "Less than 2 backups found in $BACKUP_DIR. Will not move or purge backups. Notifying DBA and exiting ..." >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
 echo "ROLL_BACKUP script is skipping the pruning phase of the backup archive process. There are less than two  backups in $BACKUP_DIR. Please Verify." | mail -s "Backup Archive Warning - $DBNAME" $MAIL_RECIP
 exit 1
fi


## Prune archived backups if they exceed longer retention policy
PURGE_COUNT=`find $BACKUP_ARCH -maxdepth 1 -mtime +$ARCHIVE_RETENTION -name "$DBNAME*001" | wc -l`

if [[ $PURGE_COUNT -gt 0 ]]
 then
  echo "Latest backup(s) to be purged from archive:" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
  find $BACKUP_ARCH -maxdepth 1 -mtime +$ARCHIVE_RETENTION -name "$DBNAME*001"| awk -F'/' '{print $NF}' | while read OLDEST_ARCH_BACKUPS
  do
        echo "   $BACKUP_ARCH/$OLDEST_ARCH_BACKUPS" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
        rm $BACKUP_ARCH/$OLDEST_ARCH_BACKUPS
  done
 else
  echo "There are no backup files older than retention requirements. No archived backups purged." >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
fi


## Display what currently exists in active and archive backup directories AFTER script run
AFTER_RETENTION_COUNT=`find  $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001" | wc -l`
AFTER_ARCHIVE_RETENTION=`find  $BACKUP_ARCH -maxdepth 1 -name "$DBNAME*001" | wc -l`

echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "(After) Number of current backups in $BACKUP_DIR: $AFTER_RETENTION_COUNT" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
find  $BACKUP_DIR -maxdepth 1 -name "$DBNAME*001"| awk -F'/' '{print $NF}' >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "(After) Number of current archived backups in $BACKUP_ARCH: $AFTER_ARCHIVE_RETENTION" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
find  $BACKUP_ARCH -maxdepth 1 -name "$DBNAME*001" | awk -F'/' '{print $NF}' >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
echo "" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log


## Clean up old log files
echo "Cleaning up old log files ..." >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log
find $OUTPUT_DIR -name "BKUP_ARCH.$DBNAME.*.log" -mtime +30 -exec rm {} \;



##### CREATE FOOTER FOR SCRIPT LOG FILE #####
echo "# # # # Script Complete - `date` # # # #" >> $OUTPUT_DIR/BKUP_ARCH.$DBNAME.$NOW.log