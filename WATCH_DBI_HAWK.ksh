#!/usr/bin/ksh

## WATCH_DBI_HAWK.ksh | March 5, 2015 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: This script watches for the DBI Brother-Hawk monitoring process to make sure monitoring is continuous. 
##          If process is missing, e-mail DBA's with next steps.
##
## Notes:
##   Edit Error Message to include proper path to start Hawk on line 33
##   Swap out <TOKEN> under Variable Assignments for Mail Recipient, Script Path. Removing <> around new values.
##
## Example Crontab:
## 0,30 * * * * . /home/db2inst1/.profile; cd /path/to/script; ./WATCH_DBI_AGENT.ksh >/dev/null 2>&1
##
## Usage: WATCH_DBI_AGENT.ksh





HAWKSTATE=$(ps -ef | grep "hawk" | grep -v grep | wc -l)
MAIL_RECIP=<Your@E-mail.here>
SCRIPT_PATH=</path/to/script>
SERVER=`hostname`

if [ $HAWKSTATE = 1 ]; then
      exit 1
else
        echo "DBI's monitoring process 'hawk.jar' is not running the repository server ($SERVER)." >> $SCRIPT_PATH/Hawk_Error.msg
        echo "This means we are blind to any alerts that would normally come from DBI." >> $SCRIPT_PATH/Hawk_Error.msg
        echo "" >> $SCRIPT_PATH/Hawk_Error.msg
        echo "Log in as DBIUSER and issue the start command:"  >> $SCRIPT_PATH/Hawk_Error.msg
        echo "   /path/to/start/hawk/startHawk.sh" >> $SCRIPT_PATH/Hawk_Error.msg

  mailx -s "ALERT: Brother-Hawk Monitoring Process is Missing" $MAIL_RECIP < $SCRIPT_PATH/Hawk_Error.msg
  rm $SCRIPT_PATH/Hawk_Error.msg

fi