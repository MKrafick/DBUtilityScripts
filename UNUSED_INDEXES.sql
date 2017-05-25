-- Purpose: Pull a list of inactive or unused indexes for a specific schema.
--
-- UNUSED_INDEXES.sql | May 25, 2017 | Version 1 | *Author Unkownn* | No warranty implied, use at your own risk.
--
-- Granularity: Medium to High 
--
-- Metrics shown:
-- Table Schema, Table Name, Index Name, Uniquness of index, What Index is composed of, Index Cardinality, 
-- Table Cardinality (as Stats understands it to be), PErcent of cardinality, Last Used 
--
-- Note on authorship: 
-- This has been in my toolbox for a few years. Pulled from an IDUG presentation so it is public domain. I don't have notes on original authorship.
-- If you recognize this SQL or are the author please let me know.
--
-- General Notes:
-- Unused indexes or indexes with poor cardinality can slow down LOAD or queries in general. This will help you asses what are index canidates that
-- could be dropped. Please be very throrough in your testing, not responsible for dropped indexes that harm systems. Use at your own risk.
--
-- Useage:
-- Replace @XX/XX/XXXX@ and @SCHEMA@ with proper date and schema, removing the @ signs.



select substr(a.tabschema,1,10) as TABSCHEMA, substr(a.tabname,1,20) as TABNAME, substr(a.INDNAME,1,40) as INDEX,
CASE
   WHEN a.UNIQUERULE = 'D' THEN 'DUP ALLOWED'
   WHEN a.UNIQUERULE = 'U' THEN 'NO DUP ALWD'
   ELSE a.UNIQUERULE
   END as UNIQUE   ,
substr(a.COLNAMES,1,80) as COLUMNS_USED,  a.FULLKEYCARD as INDEX_CARDINALITY, b.CARD as TABLE_CARDINALITY,
CASE
   WHEN a.FULLKEYCARD > 0 AND b.CARD > 0 THEN
        DECIMAL(DECIMAL(100,10,2)*(DECIMAL(a.FULLKEYCARD,12,2)/DECIMAL(b.CARD,12,2)),12,2)
   ELSE -1
   END as PERCENT_CARD, a.LASTUSED
from SYSCAT.INDEXES a, SYSCAT.TABLES b
where a.TABNAME = b.tabname and
   a.LASTUSED < '@XX/XX/XXXX@' and a.tabschema in ('@SCHEMA@') and a.UNIQUERULE <> 'P'  order by LASTUSED, TABSCHEMA, TABNAME
;