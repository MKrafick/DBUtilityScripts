-- Purpose: Matches a procedure to a package. This will help you link what function is struggling during a failed rebind
--
-- GET_PROCEDURE.sql | May 14, 2017 | Version 1 |  M. Krafick | No warranty implied, use at your own risk.
--
-- Granularity: Low.
--
-- Metrics shown:
-- PROCEDURE_NAME, PACKAGE_NAME

SELECT SUBSTR(PROCSCHEMA,1,10) as PROC_SCHEMA, SUBSTR(PROCNAME,1,30) as PROC_NAME, SUBSTR(BNAME,1,30) AS PACKAGE_NAME
FROM  SYSCAT.PROCEDURES, SYSCAT.ROUTINEDEP
WHERE SYSCAT.PROCEDURES.SPECIFICNAME=SYSCAT.ROUTINEDEP.ROUTINENAME;

