#!/usr/bin/ksh

## WATCH_PROCESS.ksh | May 23, 2017 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: This script is a generic script to look for a server level process and e-mail if it is missing
##
## Notes:
##   Swap out <TOKEN> under Variable Assignments for Mail Recipient, Script Path and search string in PROCSTATE. Removing <> around new values.
##
## Example Crontab:
## 0,30 * * * * . /home/db2inst1/.profile; cd /path/to/script; ./WATCH_PROCESS.ksh >/dev/null 2>&1
##
## Usage: WATCH_PROCESS.ksh





PROCSTATE=$(ps -ef | grep "<PROCESS_TO_WATCH>" | grep -v grep | wc -l)
MAIL_RECIP=<Your@E-mail.here>
SCRIPT_PATH=</path/to/script>
SERVER=`hostname`

if [ $PROCSTATE = 1 ]; then
      exit 1
else
        echo "Process Missing on ($SERVER)" >> $SCRIPT_PATH/Process_Error.msg

  mailx -s "Process is Missing" $MAIL_RECIP < $SCRIPT_PATH/Process_Error.msg
  rm $SCRIPT_PATH/Process_Error.msg

fi