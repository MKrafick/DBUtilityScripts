#!/bin/ksh
## MONITOR_TBSP.ksh | Dec 16, 2015 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: Look for abnormal tablespaces that could block regular access.
##          It also looks for failed tablespace space increase for things like DMS or file system full issues.
##
## Notes:
## Swap out <TOKEN> under Variable Assignments for Mail Recipient, Script Path, and Diag Path. Removing <> around new values.
##
## Usage: MONITOR_TBSP.ksh <dbname>



## Connect to Database
DBNAME=$1
db2 "connect to $DBNAME" > /dev/null


## Variable Assignments
SERVER=`hostname`
MAIL_RECIP=<Your@E-mail.com>
SCRIPTPATH=</path//to/script>
DIAGPATH=</path/to/db2/error/log>


# Clean Up msg and tmp files if left in error from ABEND
if [ -f $SCRIPTPATH/ERROR_TS.msg ];
then
rm -f $SCRIPTPATH/ERROR_TS.msg
fi

if [ -f $SCRIPTPATH/tbsp.tmp ];
then
rm -f $SCRIPTPATH/tbsp.tmp
fi

db2 -x "select substr(tbsp_name,1,20), substr(TBSP_STATE,1,20) from table (MON_GET_TABLESPACE('',-2))" > $SCRIPTPATH/tbsp.tmp
TEST_TS=`cat $SCRIPTPATH/tbsp.tmp | grep -v 'NORMAL\|BACKUP_IN_PROGRESS\|LOAD_IN_PROGRESS\|REORG_IN_PROGRESS' | wc -l`
if [ $TEST_TS -gt 0 ]; then
	echo "Tablespaces are NOT in a normal state, see below:" >> $SCRIPTPATH/ERROR_TS.msg
	echo "" >> $SCRIPTPATH/ERROR_TS.msg
	cat $SCRIPTPATH/tbsp.tmp | grep -v 'NORMAL\|BACKUP_IN_PROGRESS\|LOAD_IN_PROGRESS\|REORG_IN_PROGRESS' >> $SCRIPTPATH/ERROR_TS.msg
        rm -f $SCRIPTPATH/tbsp.tmp
fi
rm -f $SCRIPTPATH/tbsp.tmp



TEST_DIAG=`cat $DIAGPATH/db2diag.log | grep 'ADM6091W\|SQL0289N' | wc -l`
if [ $TEST_DIAG -gt 0 ]; then
	echo "" >> $SCRIPTPATH/ERROR_TS.msg
	echo "There was a failure in adjusting the size of a tablespace within the database. From the error logs:" >> $SCRIPTPATH/ERROR_TS.msg
	echo "" >> $SCRIPTPATH/ERROR_TS.msg
	cat $DIAGPATH/db2diag.log | awk -v RS='' '/SQL0289N/' >> $SCRIPTPATH/ERROR_TS.msg
	cat $DIAGPATH/db2diag.log | awk -v RS='' '/ADM6091W/' >> $SCRIPTPATH/ERROR_TS.msg
	echo "" >> $SCRIPTPATH/ERROR_TS.msg
	echo "To prevent future alerts, archive off the current db2diag.log and start a new one." >> $SCRIPTPATH/ERROR_TS.msg
fi

## Disconnect from Database
db2 "terminate" > /dev/null

## E-mail Errors, clean up message and temporary files
if [ -f $SCRIPTPATH/ERROR_TS.msg ];
then
mailx -s "Issue With Tablespace - Server: $SERVER | DB: $DBNAME" $MAIL_RECIP < $SCRIPTPATH/ERROR_TS.msg
rm -f $SCRIPTPATH/ERROR_TS.msg
fi
