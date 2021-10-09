CREATE OR REPLACE PROCEDURE load_CUSTOMERS AUTHID DEFINER IS

    v_count NUMBER;
    v_err_count NUMBER := 0;
    v_process_name VARCHAR2(255 CHAR) := 'LOAD_CUSTOMERS';
    v_date DATE := trunc(SYSDATE);
    v_err_table VARCHAR2(255) := 'ERR_CUSTOMERS';

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE ERR_CUSTOMERS';

    dbms_output.put_line('Start loading CUSTOMERS table...');

    MERGE INTO CUSTOMERS USING (
        SELECT
        dc.customer_id,
        dc.CUSTOMER_CODE,
        dc.CUSTOMER_NAME,
        dc.CUSTOMER_SURNAME,
        dc.BIRTHDAY,
        dc.SOCIAL_NUMBER,
        dcg.OWNER_NAME,
        c.COUNTRY_name COUNTRY
        from dim_customer dc join dim_cust_group dcg on dc.group_id=dcg.group_id
        join dim_country c on dc.country_code=c.country_code) custs
    ON (custs.customer_id = customers.customer_id)
    WHEN MATCHED THEN
        UPDATE SET
            customers.CUSTOMER_CODE = custs.CUSTOMER_CODE,
            customers.CUSTOMER_NAME = custs.CUSTOMER_NAME,
            customers.CUSTOMER_SURNAME = custs.CUSTOMER_SURNAME,
            customers.BIRTHDAY = custs.BIRTHDAY,
            customers.SOCIAL_NUMBER = custs.SOCIAL_NUMBER,
            customers.GROUP_OWNER = custs.OWNER_NAME,
            customers.COUNTRY = custs.COUNTRY
    WHEN NOT MATCHED THEN
        INSERT (CUSTOMER_ID, CUSTOMER_CODE, CUSTOMER_NAME, CUSTOMER_SURNAME, BIRTHDAY, SOCIAL_NUMBER, GROUP_OWNER, COUNTRY)
        VALUES (
            custs.CUSTOMER_ID,
            custs.CUSTOMER_CODE,
            custs.CUSTOMER_NAME,
            custs.CUSTOMER_SURNAME,
            custs.BIRTHDAY,
            custs.SOCIAL_NUMBER,
            custs.OWNER_NAME,
            custs.COUNTRY
        )
    LOG ERRORS INTO ERR_CUSTOMERS(v_process_name) REJECT LIMIT UNLIMITED;
    v_count :=  SQL%ROWCOUNT;
    COMMIT;

    dbms_output.put_line(v_count||' rows inserted or updated');

    SELECT count(*) INTO v_err_count FROM ERR_CUSTOMERS;

    IF v_err_count != 0 THEN
        load_ERROR_TABLE_LOG(v_date,v_err_table);
        dbms_output.put_line('Found '||v_err_count||' rows rejected. Check error tables for details.');
    END IF;

    EXCEPTION
      WHEN OTHERS THEN
         dbms_output.put_line('ERROR: Unexpected error occurred...');
         dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END load_CUSTOMERS;
/