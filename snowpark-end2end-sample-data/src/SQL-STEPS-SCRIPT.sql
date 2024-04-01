-- STEP 02 - CREATE SCHEMA 
SELECT CURRENT_WAREHOUSE();

create schema if not exists DEMO_DB.ALF_SOURCE; -- will have source stage etc
create schema if not exists DEMO_DB.ALF_CURATED; -- data curation and de-duplication
create schema if not exists DEMO_DB.ALF_consumption; -- fact & dimension
create schema if not exists DEMO_DB.ALF_audit; -- to capture all audit records
create schema if not exists DEMO_DB.ALF_common; -- for file formats sequence object etc


-- STEP 03 - CREATE INTERNAL STAGE IN SOURCE SCHEMA 
CREATE STAGE IF NOT EXISTS DEMO_DB.ALF_SOURCE.MY_INTERNAL_STAGE;
DESC STAGE DEMO_DB.ALF_SOURCE.MY_INTERNAL_STAGE;


-- LIST FILE IN STAGE 
LS @DEMO_DB.ALF_SOURCE.MY_INTERNAL_STAGE/source=FR/;



-- STEP 04 - LOAD ORDER FILES TO SATGE LOCATION

-- you can use vs code or command or script python  
-- following put command can be executed
/*
-- csv example
put file:///tmp/sales/source=IN/format=csv/date=2022-02-22/order-20220222.csv @sales_dwh.source.my_internal_stg/sales/source=IN/format=csv/date=2022-02-22 auto_compress=False overwrite=True, parallel=3 ;
put file:///tmp/sales/source=IN/format=csv/date=2021-04-26/order-20210426.csv @sales_dwh.source.my_internal_stg/sales/source=IN/format=csv/date=2021-04-26 auto_compress=False overwrite=True, parallel=3 ;

-- json example
put file:///tmp/sales/source=FR/format=json/date=2022-02-22/order-20220222.json @sales_dwh.source.my_internal_stg/sales/source=FR/format=json/date=2022-02-22 auto_compress=False overwrite=True, parallel=3 ;
put file:///tmp/sales/source=FR/format=json/date=2021-04-26/order-20210426.json @sales_dwh.source.my_internal_stg/sales/source=FR/format=json/date=2021-04-26 auto_compress=False overwrite=True, parallel=3 ;

-- parquet example
put file:///tmp/sales/source=US/format=parquet/date=2022-02-22/order-20220222.snappy.parquet @sales_dwh.source.my_internal_stg/sales/source=US/format=parquet/date=2022-02-22 auto_compress=False overwrite=True, parallel=3 ;
put file:///tmp/sales/source=US/format=parquet/date=2021-04-26/order-20210426.snappy.parquet @sales_dwh.source.my_internal_stg/sales/source=US/format=parquet/date=2021-04-26 auto_compress=False overwrite=True, parallel=3 ;
*/


-- STEP 05: FILE FORMATS IN COMMON SCHEMA

use schema common;
-- create file formats csv (India), json (France), Parquet (USA)
create or replace file format DEMO_DB.ALF_COMMON.my_csv_format
  type = csv
  field_delimiter = ','
  skip_header = 1
  null_if = ('null', 'null')
  empty_field_as_null = true
  field_optionally_enclosed_by = '\042'
  compression = auto;

-- json file format with strip outer array true
create or replace file format DEMO_DB.ALF_COMMON.my_json_format
  type = json
  strip_outer_array = true
  compression = auto;

-- parquet file format
create or replace file format DEMO_DB.ALF_COMMON.my_parquet_format
  type = parquet
  compression = snappy;

  SHOW FILE FORMATS IN SCHEMA DEMO_DB.ALF_COMMON;


-- Step-5.1 Select Statements On Internal Stage (CSV, Parquet, JSON)


-- Internal Stage - Query The CSV Data File Format
/*
Once the 3 file formats data loaded into the snowflake internal stage, following select statement can be executed to see if the data is looking good before we move and insert into source schema.



 */
select 
    t.$1::text as order_id, 
    t.$2::text as customer_name, 
    t.$3::text as mobile_key,
    t.$4::number as order_quantity, 
    t.$5::number as unit_price, 
    t.$6::number as order_valaue,  
    t.$7::text as promotion_code , 
    t.$8::number(10,2)  as final_order_amount,
    t.$9::number(10,2) as tax_amount,
    t.$10::date as order_dt,
    t.$11::text as payment_status,
    t.$12::text as shipping_status,
    t.$13::text as payment_method,
    t.$14::text as payment_provider,
    t.$15::text as mobile,
    t.$16::text as shipping_address
 from 
   @DEMO_DB.ALF_SOURCE.MY_INTERNAL_STAGE/source=IN/format=csv/
   (file_format => 'DEMO_DB.ALF_COMMON.my_csv_format') t; 

-- Internal Stage - Query The Parquet Data File Format
select 
  $1:"Order ID"::text as orde_id,
  $1:"Customer Name"::text as customer_name,
  $1:"Mobile Model"::text as mobile_key,
  to_number($1:"Quantity") as quantity,
  to_number($1:"Price per Unit") as unit_price,
  to_decimal($1:"Total Price") as total_price,
  $1:"Promotion Code"::text as promotion_code,
  $1:"Order Amount"::number(10,2) as order_amount,
  to_decimal($1:"Tax") as tax,
  $1:"Order Date"::date as order_dt,
  $1:"Payment Status"::text as payment_status,
  $1:"Shipping Status"::text as shipping_status,
  $1:"Payment Method"::text as payment_method,
  $1:"Payment Provider"::text as payment_provider,
  $1:"Phone"::text as phone,
  $1:"Delivery Address"::text as shipping_address
from 
     @DEMO_DB.ALF_SOURCE.MY_INTERNAL_STAGE/source=US/format=parquet/
     (file_format => 'DEMO_DB.ALF_COMMON.my_parquet_format');

-- Internal Stage - Query The JSON Data File Format
select                                                       
    $1:"Order ID"::text as orde_id,                   
    $1:"Customer Name"::text as customer_name,          
    $1:"Mobile Model"::text as mobile_key,              
    to_number($1:"Quantity") as quantity,               
    to_number($1:"Price per Unit") as unit_price,       
    to_decimal($1:"Total Price") as total_price,        
    $1:"Promotion Code"::text as promotion_code,        
    $1:"Order Amount"::number(10,2) as order_amount,    
    to_decimal($1:"Tax") as tax,                        
    $1:"Order Date"::date as order_dt,                  
    $1:"Payment Status"::text as payment_status,        
    $1:"Shipping Status"::text as shipping_status,      
    $1:"Payment Method"::text as payment_method,        
    $1:"Payment Provider"::text as payment_provider,    
    $1:"Phone"::text as phone,                          
    $1:"Delivery Address"::text as shipping_address
from                                                
@DEMO_DB.ALF_SOURCE.MY_INTERNAL_STAGE/source=FR/format=json/
(file_format => DEMO_DB.ALF_COMMON.my_json_format);
