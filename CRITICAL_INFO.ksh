#!/bin/ksh
## CRITICAL_INFO.ksh | June 15, 2017 | Version 1 | M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: Quick hit script to grab some details before major DB work or change window.
##
## Execution notes:
## Quickly grabs some basic critical information about the database and places the details in the directory you are in.
## Note that sometimes NODE information comes back empty if there are no cataloged databases.
## Usage: ./CRITICAL_INFO.ksh <dbname> 
##

DBNAME=$1

db2set -all > db2set.$DBNAME.ORIG
db2 get dbm cfg > DBM.CFG.$DBNAME.ORIG
db2 get db cfg for $DBNAME > DB.CFG.$DBNAME.ORIG
db2 list node directory > NODE.DIR.$DBNAME.ORIG
db2 list database directory > DB.DIR.$DBNAME.ORIG
db2look -d $DBNAME -l -e -x -o DB2LOOK.$DBNAME.ORIG
db2level >  DB2LEVEL.ORIG
db2pd -d $DBNAME -tablespaces > TABLESPACE.$DBNAME.ORIG
db2pd -d $DBNAME -storagepaths > STORAGEPATHS.$DBNAME.ORIG