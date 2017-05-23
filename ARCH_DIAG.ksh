#!/usr/bin/ksh
## ARCH_DIAG.ksh | Aug 1, 2013 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: To archive the DB2 Error and Notify Log files (db2diag.log and instance.nfy) and append with a timestamp
##
## Notes:
## Assumes that your error logs are in the standard location of INSTANCEHOME/sqllib/db2dump
##
## Usage: ARCH_DIAG.ksh ,DB2 Instance>



## Variable Assignments
NOW=`date '+%Y%m%d%H%M%S'`
INSTANCE=$1

## Archive DB2DIAG.log and INSTANCE.NFY (Schedule in crontab for 11:59pm)
find ~/sqllib/db2dump/ -name 'db2diag.log' | xargs -I {} mv {} ~/sqllib/db2dump/db2diag.$NOW.log
find ~/sqllib/db2dump/ -name "$INSTANCE.nfy" | xargs -I {} mv {} ~/sqllib/db2dump/$INSTANCE.$NOW.nfy

## Purged Archive logs after 30 days.
find ~/sqllib/db2dump/ -name 'db2diag.*.log' -mtime +30 -exec rm {} \;
find ~/sqllib/db2dump/ -name "$INSTANCE.*.nfy"  -mtime +30 -exec rm {} \;

## Create clean log, set permissions
touch ~/sqllib/db2dump/db2diag.log
touch ~/sqllib/db2dump/$INSTANCE.nfy
chmod 775 ~/sqllib/db2dump/db2diag.log
chmod 775 ~/sqllib/db2dump/$INSTANCE.nfy

