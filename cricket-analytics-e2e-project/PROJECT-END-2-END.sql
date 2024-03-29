USE ROLE DEV_ENT_DW_ENGINEER_FR;
USE WAREHOUSE DEMO_WH;

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
METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$FILE_CONTENT_KEY, METADATA$FILE_LAST_MODIFIED, METADATA$START_SCAN_TIME
 ,T.$1:meta::VARIANT AS META
 ,T.$1:info::VARIANT AS INFO
 ,T.$1:innings::ARRAY AS INNINGS

FROM @DEMO_DB.ALF_LAND.STG_LAND/cricket/json/1384401.json.gz 
(FILE_FORMAT => 'DEMO_DB.ALF_LAND.FF_LAND_JSON') T
;

-- CREATE EXTERNAL TABLE 
CREATE OR REPLACE  TRANSIENT TABLE DEMO_DB.ALF_RAW.MATCH_RAW_TBL(
    META OBJECT NOT NULL,
    INFO VARIANT NOT NULL,
    INNINGS ARRAY NOT NULL,
    STG_FILE_NAME TEXT NOT NULL,
    STG_FILE_ROW_NUMBER INT NOT NULL,
    STG_FILE_HASHKEY TEXT NOT NULL,
    STG_FILE_MODIFIED_TS TIMESTAMP NOT NULL

) 
COMMENT = 'This is a raw table to store all the json data file with root element extracted';
;

COPY INTO DEMO_DB.ALF_RAW.MATCH_RAW_TBL FROM (

SELECT 
T.$1:meta::VARIANT AS META
,T.$1:info::VARIANT AS INFO
,T.$1:innings::ARRAY AS INNINGS,

-- 

METADATA$FILENAME,
METADATA$FILE_ROW_NUMBER,
METADATA$FILE_CONTENT_KEY, 
METADATA$FILE_LAST_MODIFIED

FROM @DEMO_DB.ALF_LAND.STG_LAND/cricket/json 
(FILE_FORMAT => 'DEMO_DB.ALF_LAND.FF_LAND_JSON') T);

SELECT COUNT(*) FROM DEMO_DB.ALF_RAW.MATCH_RAW_TBL;
SELECT * FROM DEMO_DB.ALF_RAW.MATCH_RAW_TBL;


