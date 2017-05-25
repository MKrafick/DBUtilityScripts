-- Purpose: Matches a function to a package. This will help you link what function is struggling during a failed rebind
--
-- GET_FUNCTION.sql | May 14, 2017 | Version 1 |  M. Krafick | No warranty implied, use at your own risk.
--
-- Granularity: Low. 
--
-- Metrics shown:
-- FUNCTION_NAME, PACKAGE_NAME


SELECT SUBSTR(FUNCSCHEMA,1,10) AS FUNCTION_SCHEMA, substr(FUNCNAME,1,40) AS FUNCTION_NAME, substr(BNAME,1,40) AS PACKAGE_NAME
FROM SYSCAT.FUNCTIONS, SYSCAT.ROUTINEDEP
WHERE SYSCAT.FUNCTIONS.SPECIFICNAME=SYSCAT.ROUTINEDEP.ROUTINENAME;