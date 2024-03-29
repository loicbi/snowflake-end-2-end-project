USE ROLE DEV_ENT_DW_ENGINEER_FR;
USE WAREHOUSE LOAD_WH;

USE DATABASE DEMO_DB;

-- CREATE SCHEMA 
CREATE SCHEMA IF NOT EXISTS  DEMO_DB.ALF_LAND;
CREATE SCHEMA IF NOT EXISTS  DEMO_DB.ALF_RAW;
CREATE SCHEMA IF NOT EXISTS  DEMO_DB.ALF_CLEAN;
CREATE SCHEMA IF NOT EXISTS  DEMO_DB.ALF_CONSUMPTION;

SHOW SCHEMAS IN DATABASE DEMO_DB;

-- CREATE FILE FORMAT IN LAND 
CREATE FILE FORMAT IF NOT EXISTS DEMO_DB.ALF_LAND.FF_LAND_JSON
    TYPE = JSON 
    NULL_IF = ('\\n', 'null', '')
    STRIP_OUTER_ARRAY = TRUE
    COMMENT = 'JSON FILE FORMAT WITH OUTER STRIP ARRAY FLAG TRUE';

-- CREATE INTERNAL STAGE 
CREATE OR REPLACE STAGE DEMO_DB.ALF_LAND.STG_LAND
;

-- LIST STAGE INTERNAL 
LIST @DEMO_DB.ALF_LAND.STG_LAND;

-- CHECK IF MY DATA IS CORRECT 
-- https://docs.snowflake.com/en/user-guide/querying-metadata
SELECT 
METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$FILE_CONTENT_KEY, METADATA$FILE_LAST_MODIFIED, METADATA$START_SCAN_TIME,
T.$1
FROM @DEMO_DB.ALF_LAND.STG_LAND/cricket/json/1384401.json  T
(FILE_FORMAT => 'DEMO_DB.ALF_LAND.FF_LAND_JSON')
;
