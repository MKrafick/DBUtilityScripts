#!/bin/ksh
## WATCH_DBI_AGENT.ksh | March 5, 2015 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: This script watches for the DBI pureSuite collector process to make database data is being collected. 
##          If process is missing, e-mail DBA's with next steps.
##
## Notes:
##   Edit Error Message to include proper path to start Hawk on line 28
##   Swap out <TOKEN> under Variable Assignments for Mail Recipient, Script Path. Removing <> around new values.
##
## Example Crontab:
## 0,30 * * * * . /home/db2inst1/.profile; cd /path/to/script; ./WATCH_DBI_AGENT.ksh >/dev/null 2>&1
##
## Usage: WATCH_DBI_AGENT.ksh

DBISTATE=$(ps -ef | grep "dbimgr" | grep -v grep | wc -l)
MAIL_RECIP=<Your@E-mail.com>
SCRIPT_PATH=</path/to/script>
SERVER=`hostname`

if [ $DBISTATE = 1 ]; then
      exit 1
else
        echo "DBI's client agent 'dbimgr' is not running on monitored server ($SERVER)" >> $SCRIPT_PATH/Agent_Error.msg
        echo "This means we are not actively collecting data to send to the DBI Repository." >> $SCRIPT_PATH/Agent_Error.msg
        echo "" >> $SCRIPT_PATH/Agent_Error.msg
        echo "Log in as DB2 instance ID and issue the start command:"  >> $SCRIPT_PATH/Agent_Error.msg
        echo "   /path/to/start/collector/start_dbi_collector.sh" >> $SCRIPT_PATH/Agent_Error.msg

  mailx -s "ALERT: DBI Agent Process is Missing" $MAIL_RECIP < $SCRIPT_PATH/Agent_Error.msg
  rm $SCRIPT_PATH/Agent_Error.msg

fi