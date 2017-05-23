#!/bin/ksh
## VOLATILE.RUNSTATS.ksh | April 27th, 2017| Version 1 | Script: M. Krafick |  No warranty implied, use at your own risk.
##
## Purpose:
## Runstats on volatile tables can be tough to do because of the wild swing of row counts. This script is meant to be run at an interval throughout the day.
## If the script picks up more than a 30% variance between actual row count and what it thinks is the row count (cardinality), runstats will be executed for
## tables listed in a specific list. For a positive change (more actual than cardinality) runstats is tripped at 30% change on a table of 1 Million rows
## or higher. For a negative change (cardinality is higher than actual) runstats is automatically tripped.
##
## Requirements:
## A single VOLATILE.LIST the same subdirectory as this one, one table name per row.
##
## Notes:
## Swap out <TOKEN> under Variable Assignments for database name, table schema, script path, output path, and e-mail recipient. 
## Removing <> around new values
##
## Usage: VOLATILE.RUNSTATS.ksh




## Variable List and Assignment

DBNAME=<DBNAME>
SCHEMA=<SCHEMA>
SCRIPTPATH=</path/to/script>
SCRIPTOUTPUT=<path/to/output>
VOLATILE_LIST=$SCRIPTPATH/VOLATILE.LIST
NOW=`date '+%Y%m%d%H%M%S'`
MAIL_RECIP=<Your@E-mail.com>


## Clean up from abnormally terminated runs
 if [ -f $SCRIPTPATH/ACTUAL_VS_CARD.sql ];
   then
   rm -f $SCRIPTPATH/ACTUAL_VS_CARD.sql
 fi

 if [ -f $SCRIPTPATH/TABLE_CHECK.tmp ];
   then
   rm -f $SCRIPTPATH/TABLE_CHECK.tmp
 fi


## Scan specific list of volatile tables for runstats consideration
 cat $SCRIPTPATH/VOLATILE.LIST | while read LINE
 do
  echo "select A.TABNAME, (select count(*) from $SCHEMA.$LINE) AS COUNT, A.CARD FROM SYSCAT.TABLES A WHERE A.TABNAME = '$LINE' WITH UR;" >> $SCRIPTPATH/ACTUAL_VS_CARD.sql
 done

## Pull list - Actual Table Row Count vs. System Understanding of Table Cardinality
db2 "connect to $DBNAME" > /dev/null 
db2 -txf $SCRIPTPATH/ACTUAL_VS_CARD.sql >> $SCRIPTPATH/TABLE_CHECK.tmp 
db2 "termnate" > /dev/null

sed -i '/^$/d' $SCRIPTPATH/TABLE_CHECK.tmp   ## Clean/Scrub - Delete extraneous empty rows in output


## Generate list of tables to execute runstats on.

awk -F, '{print $1, $2, $3}' $SCRIPTPATH/TABLE_CHECK.tmp | while read TABLE ACTUAL CARD
do

## No Stats exist at all, generate RUNSTATS command regardless
if [[ $CARD -eq '-1' ]]
    then
       echo "" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
       echo "--No Stats Collected, Automatic Run, not in Else statement" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
       echo "RUNSTATS ON TABLE $SCHEMA.$TABLE WITH DISTRIBUTION ON ALL COLUMNS AND INDEXES ALL SHRLEVEL CHANGE;" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
fi


## Positive Percentage Change - Actual count is GREATER than expected cardinality
if [[ $ACTUAL -gt $CARD  &&  $ACTUAL -gt 1000000 ]]
     then
       VARIABLE_LINE="$ACTUAL $CARD"
       POS_PERCENTAGE_DIFF=$(echo $VARIABLE_LINE|awk '{print int((($1 - $2)/$1) * 100)}')
       if [[ $POS_PERCENTAGE_DIFF -ge '30' ]]
         then
         echo "" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
         echo "--POSITIVE Percentage Difference is: $POS_PERCENTAGE_DIFF - Actual Rows: $ACTUAL Cardinality: $CARD" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
         echo "RUNSTATS ON TABLE OMSUSR.$TABLE WITH DISTRIBUTION ON ALL COLUMNS AND INDEXES ALL SHRLEVEL CHANGE;" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
       fi
fi

## Negative Percentage Change - Actual count is LESS than expected cardinality
if [[ $ACTUAL -lt $CARD ]]
     then
       VARIABLE_LINE="$ACTUAL $CARD"
       NEG_PERCENTAGE_DIFF=$(echo $VARIABLE_LINE|awk '{print int((($2 - $1)/$2) * 100)}')
       if [[ $NEG_PERCENTAGE_DIFF -ge '30' ]]
         then
         echo "" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
         echo "--NEGATIVE Percentage Difference is: $NEG_PERCENTAGE_DIFF - Actual Rows: $ACTUAL Cardinality: $CARD" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
         echo "RUNSTATS ON TABLE OMSUSR.$TABLE WITH DISTRIBUTION ON ALL COLUMNS AND INDEXES ALL SHRLEVEL CHANGE;" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
       fi
fi

done

## If a new RUNSTATS was generated: execute it, e-mail DBA, clean up after itself
 if [ -f $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql ];
   then
      sed -i "1s/^/--TIMESTAMP:$NOW\n \nCONNECT TO $DBNAME ;\n/" $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
      echo "" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql
      echo "TERMINATE;" >> $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql

     db2 -tvf $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql > $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.out

      mailx -s "RUNSTATS GENERATED - DB: $DBNAME SCHEMA: $SCHEMA " $MAIL_RECIP < $SCRIPTOUTPUT/VOLATILE_RUNSTATS_$NOW.sql

 fi

## Clean Up after itself
 if [ -f $SCRIPTPATH/ACTUAL_VS_CARD.sql ];
   then
   rm -f $SCRIPTPATH/ACTUAL_VS_CARD.sql
 fi

 if [ -f $SCRIPTPATH/TABLE_CHECK.tmp ];
   then
   rm -f $SCRIPTPATH/TABLE_CHECK.tmp
 fi

