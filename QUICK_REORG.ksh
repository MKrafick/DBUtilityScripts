#!/bin/ksh
## QUICK_REORG.ksh | May 24, 2017 | Version 1 | Script: M. Krafick | No warranty implied, use at your own risk.
##
## Purpose: Very quick and dirty way to REORG tables and indexes by schema. Not a robust nor advanced script. Tweak as needed.
##
## Usage: QUICK_REORG.ksh <DBNAME> <SCHEMA>

DBNAME=$1
CREATOR=$2

date
db2 "connect to $DBNAME"
db2 "select 'TABLINE', tabname from syscat.tables where tabschema='$CREATOR' and type='T' and volatile<>'C' and card >'0' and lastused<>'0001-01-01'"|grep 'TABLINE'|cut -c8-55 > out.temp
DBTABLES="`cat out.temp`"

for TBNAME in $DBTABLES
 do
 echo "Performing reorg on table and indexes for $CREATOR.$TBNAME"
 db2 "reorg table $CREATOR.$TBNAME"
 db2 "reorg indexes all for table $CREATOR.$TBNAME"
 done

db2 terminate
date

rm out.temp