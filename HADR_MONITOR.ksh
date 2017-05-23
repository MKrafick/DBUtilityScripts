#!/bin/ksh
## HADR_MONITOR.ksh | Dec 14, 2015 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: Verify HADR is online, in peer state, and uncongested. Email address or list if there is an issue.
##          It also looks for failed tablespace space increase for things like DMS or file system full issues.
##          This is a stand alone script, that can be called in crontab.
##          This is not meant as a hook into 3rd party tool like HADR_CONGESTION_HOOK.sql or HADR_DISCONNECT_HOOK.sql
##
## Notes:
## Swap out <TOKEN> under Variable Assignments for Mail Recipient, Script Path. Removing <> around new values.
## Install on Primary HADR server only
##
## Usage: HADR_MONITOR.ksh <dbname>


## Define Variables and Output Files
## DBNAME                       Database Name, passed via command line
## SCRIPTPATH                   Where the script and temp files are housed
## SERVER                       Hostname of the server script is running
## MAIL_RECIP                   E-mail or Mailing List to send error report too
## CUR_ID                       DB2's Understanding of HADR_TARGET_LIST, what order to failover in
## CUR_ROLE                     PRIMARY or STANDBY, what DB2 understands this specific servers purpose is
## CUR_STATE                    PEER, CATCHUP, etc - it's progress with sending and processing log files
## CUR_CON_STAT                 CONNECTED, DISCONNECTED from its standby server
## CUR_LOG_GAP                  Current LOG GAP in Bytes in between primary and stancby logs
## LOGFILSIZ                    Determine DB2 Log File Size in Bytes
## LOGLAG                       Threshold Value used for comparison, 10% of LOGFILSZ
## HADR.TMP                     Temporary file from HADR query output used to extrapolate variables and status. Removed at end of script.
## HADR_STATE_ERROR.MSG         Error log generated on failure which is sent to DBA.

# Clean Up msg and tmp files if left in error from ABEND
if [ -f $SCRIPTPATH/HADR_STATE_ERROR.msg ];
then
rm -f $SCRIPTPATH/HADR_STATE_ERROR.msg
fi

if [ -f $SCRIPTPATH/hadr.tmp ];
then
rm -f $SCRIPTPATH/hadr.tmp
fi


## Connect to Database, alert failover if SQL1776N
DBNAME=$1
SERVER=`hostname`
SCRIPTPATH=</path/to/script>
MAIL_RECIP=<Your@E-mail.com>

db2 "connect to $DBNAME" > /dev/null

if [ $? != 0 ]; then
      echo " ~ ~ ~ " >> $SCRIPTPATH/HADR_STATE_ERROR.msg
      echo "Primary database $DBNAME is not connectible, possible HADR failover." >> $SCRIPTPATH/HADR_STATE_ERROR.msg

      mailx -s "Possible HADR Failover - Server: $SERVER | DB: $DBNAME" $MAIL_RECIP < $SCRIPTPATH/HADR_STATE_ERROR.msg

      rm -f $SCRIPTPATH/HADR_STATE_ERROR.msg
      exit 1
fi


## Check for various HADR States and congestions, e-mail if issue.
## Generate HADR.TMP file for variable extraction and assignments
db2 -x "select STANDBY_ID, HADR_ROLE, HADR_STATE, HADR_CONNECT_STATUS, HADR_LOG_GAP from table (mon_get_hadr(NULL)) where STANDBY_ID='1'" | awk '{print $1,$2,$3,$4,$5}' > $SCRIPTPATH/had
r.tmp

## Set Variables
CUR_ID=`cat $SCRIPTPATH/hadr.tmp | awk '{print $1}'`
CUR_ROLE=`cat $SCRIPTPATH/hadr.tmp | awk '{print $2}'`
CUR_STATE=`cat $SCRIPTPATH/hadr.tmp | awk '{print $3}'`
CUR_CON_STAT=`cat $SCRIPTPATH/hadr.tmp | awk '{print $4}'`
CUR_LOG_GAP=`cat $SCRIPTPATH/hadr.tmp | awk '{print $5}'`
LOGFILSIZ=`db2 -x "SELECT VALUE FROM SYSIBMADM.DBCFG WHERE NAME IN ('logfilsiz')"`
LOGLAG=$(((${LOGFILSIZ}*4096)*.10))


## Various HADR Tests - Role, State, Connection Status, Log Gap
if [ $CUR_ROLE != 'PRIMARY' ]; then
      echo " ~ ~ ~ " >> $SCRIPTPATH/HADR_STATE_ERROR.msg
      echo "Primary database server $SERVER is no longer listed as primary, possible HADR failover." >> $SCRIPTPATH/HADR_STATE_ERROR.msg
      echo "" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
      echo "Current Role is: $CUR_ROLE" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
fi

if [ $CUR_STATE != 'PEER' ]; then
     echo " ~ ~ ~ " >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "Primary database server $SERVER is not in PEER state. Check for REMOTE_CATCHUP, etc"  >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "Current State is: $CUR_STATE"  >> $SCRIPTPATH/HADR_STATE_ERROR.msg
fi

if [ $CUR_CON_STAT != 'CONNECTED' ]; then
     echo " ~ ~ ~ "  >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "Primary database server $SERVER is not CONNECTED state at the moment. Check for HADR Congestion or Disconnect." >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "Current Connection Status: $CUR_CON_STAT" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
fi

if [ $CUR_LOG_GAP -gt $LOGLAG ]; then
     echo " ~ ~ ~ " >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "Standby Server to host $SERVER seems to be more than 10% behind in applying logs." >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
     echo "This could be due to reorg/runstats or normal congestion. Please investigate. Current gap of $CUR_LOG_GAP bytes" >> $SCRIPTPATH/HADR_STATE_ERROR.msg
fi


## Disconnect from Database
db2 "terminate" > /dev/null


## E-mail Errors, clean up message and tewmporary files
if [ -f $SCRIPTPATH/HADR_STATE_ERROR.msg ];
then
mailx -s "Possible HADR Error - Server: $SERVER | DB: $DBNAME" $MAIL_RECIP < $SCRIPTPATH/HADR_STATE_ERROR.msg
rm -f $SCRIPTPATH/HADR_STATE_ERROR.msg
fi

if [ -f $SCRIPTPATH/hadr.tmp ];
then
rm -f $SCRIPTPATH/hadr.tmp
fi