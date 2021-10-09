SET serveroutput on
SET pagesize 5000
SET long 5000
SET pages 500
SET linesize 300
SET echo on
SET serveroutput on
--WHENEVER SQLERROR EXIT

prompt
prompt Generating data in DIM_DATE...
EXECUTE generateDimData.load_DIM_DATE;
prompt
prompt
prompt Generating data in DIM_CUST_GROUP...
EXECUTE generateDimData.load_DIM_CUST_GROUP(10);
prompt
prompt
prompt Generating data in DIM_CUSTOMER...
EXECUTE generateDimData.load_DIM_CUSTOMER(100);
prompt
prompt
prompt Generating data in DIM_ACCOUNT...
EXECUTE generateDimData.load_DIM_ACCOUNT(100);
prompt
prompt
prompt Generating data in FACT_DAY_RATES...
EXECUTE generateFactData.load_FACT_DAY_RATES;
prompt
prompt
prompt Generating data in FACT_TRANSACTIONS...
EXECUTE generateFactData.load_FACT_TRANSACTIONS;
prompt


EXECUTE dbms_output.put_line('Load data process finished!');
--exit