# DBUtilityScripts
KSH and SQL used for maintaining a DB2 Database on LUW

### Disclaimer:
I am not an advanced scripter or SQL writer. Use these at your own risk.

### Purpose:
These are various "time savers" I use to feed and care for my DB2 environment. A lot have to do with general maintenance and monitoring and some are quick and dirty time savers. You may see some clean and well documented code and you may see a quick hack job. So use or manipulate at your own risk.

### Notes:
None.

### Pre-Requisites:
None per se, but read the comments in each before making assumptions.

### Available SQL and Scripts:

*ARCH_DIAG.ksh*

To archive the DB2 Error and Notify Log files (db2diag.log and instance.nfy) and append with a timestamp.


*Automated_Reboot.zip*

These scripts can be called by server or admin to bring DB2 instances, databases, and DBI tooling up and down gracefully.
This will account for multiple instances, versions, and databases.	If not using the DBI pureSuite of products, edit and remove as necessary.
Note that some alteration is needed (path to Db2 binaries, etc).


*CHK_BKUP.ksh*

Confirms X amount of backups are on disk and that at least one is less than X days old. E-mail an alert if failure.	


*CRITICAL_INFO.ksh*	

Quick hit script to grab some details (to help with recovery) before major DB work or change window.


*GET_FUNCTION.sql*

Matches a function to a package. This will help you link what function is struggling during a failed rebind.


*GET_PROCEDURE.sql*

Matches a procedure to a package. This will help you link what function is struggling during a failed rebind.


*HADR_MONITOR.ksh*

Verify HADR is online, in peer state, and uncongested. Email address or list if there is an issue.
This is a stand alone script, that can be called in crontab.
This is not meant as a hook into 3rd party tool like HADR_CONGESTION_HOOK.sql or HADR_DISCONNECT_HOOK.sql


*MONITOR_TBSP.ksh*

Look for abnormal tablespaces that could block regular access.
It also looks for failed tablespace space increase for things like DMS or file system full issues.


*PowerHA_Reboot_Scripts.zip*	

This script is called by HACMP/PowerHA to start DB2 and activate databases.
This is developed to work with one or many DB2 instances and databases on a single node HACMP/PowerHA configuration.                                
Some logic or direct code is based off IBM's sample script: ~/sqllib/samples/hacmp/hacmp-s1.sh   
**Note**: This is the original version developed in 2012 with zero updates. No longer have environment to test in. Use at own risk.


*QUICK_REORG.ksh*	

Very quick and dirty way to REORG tables and indexes by schema. Not a robust nor advanced script. Tweak as needed.


*UNUSED_INDEXES.sql*

Pull a list of inactive or unused indexes for a specific schema.


*VOLATILE.RUNSTATS.ksh*	

Runstats on volatile tables can be tough to do because of the wild swing of row counts. This script is meant to be run at an interval throughout the day.
If the script picks up more than a 30% variance between actual row count and what it thinks is the row count (cardinality), runstats will be executed for
tables listed in a specific list. For a positive change (more actual than cardinality) runstats is tripped at 30% change on a table of 1 Million rows
or higher. For a negative change (cardinality is higher than actual) runstats is automatically tripped.


*WATCH_DBI_AGENT.ksh*

This script watches for the DBI pureSuite collector process to make database data is being collected. 
If process is missing, e-mail DBA's with next steps.


*WATCH_DBI_HAWK.ksh*

This script watches for the DBI Brother-Hawk monitoring process to make sure monitoring is continuous. 
If process is missing, e-mail DBA's with next steps.


*WATCH_PROCESS.ksh*

This script is a generic script to look for a server level process and e-mail if it is missing. Neutered version of my DBI scripts to be general purpose.
