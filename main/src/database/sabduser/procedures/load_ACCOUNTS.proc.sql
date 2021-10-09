CREATE OR REPLACE PROCEDURE load_ACCOUNTS AUTHID DEFINER IS

    v_count NUMBER;
    v_err_count NUMBER := 0;
    v_process_name VARCHAR2(255 CHAR) := 'LOAD_ACCOUNTS';
    v_date DATE := trunc(SYSDATE);
    v_err_table VARCHAR2(255) := 'ERR_ACCOUNTS';

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE ERR_ACCOUNTS';

    dbms_output.put_line('Start loading ACCOUNTS table...');

    MERGE INTO ACCOUNTS USING (
        WITH acct_access AS (
            SELECT dc.group_id,
               CASE WHEN da.is_group_shared = 'Y'
                AND upper(customer_name||' '||customer_surname) != upper(dcg.owner_name)
                THEN dc.customer_name||' '||dc.customer_surname
                END CST
        FROM dim_account da JOIN dim_customer dc ON da.customer_id=dc.customer_id
        JOIN dim_cust_group dcg ON dc.group_id=dcg.group_id)
        , lagSharedWith AS (
            SELECT group_id,
                   decode(lag(CST) OVER (PARTITION BY NULL ORDER BY CST),CST,NULL,CST) AS LAGCST
            FROM acct_access
        )
        , listaggRes AS (
            SELECT group_id,
                   listagg(LAGCST,', ') WITHIN GROUP ( ORDER BY group_id) SHARED_WITH
            FROM lagSharedWith
            GROUP BY group_id
        )
        SELECT
        ACCOUNT_ID,
        OPEN_DATE,
        CONTAINER_CODE,
        ACCOUNT_CODE,
        ACCOUNT_TYPE,
        (SELECT customer_code FROM dim_customer WHERE upper(customer_name||' '||customer_surname) = upper(dcg.owner_name)) CONTAINER_OWNER,
        SHARED_WITH,
        CUSTOMER_CODE,
        ACCOUNT_CCY_CODE CCY_CODE,
        BALANCE
        FROM dim_account da JOIN dim_customer dc ON da.customer_id=dc.customer_id
        JOIN dim_cust_group dcg ON dc.group_id=dcg.group_id
        JOIN listaggRes ON listaggRes.group_id=dc.group_id) accts
    ON (accts.account_id = accounts.account_id)
    WHEN MATCHED THEN
        UPDATE SET
            ACCOUNTS.OPEN_DATE = accts.OPEN_DATE,
            ACCOUNTS.CONTAINER_CODE = accts.CONTAINER_CODE,
            ACCOUNTS.ACCOUNT_CODE = accts.ACCOUNT_CODE,
            ACCOUNTS.ACCOUNT_TYPE = accts.ACCOUNT_TYPE,
            ACCOUNTS.CONTAINER_OWNER = accts.CONTAINER_OWNER,
            ACCOUNTS.SHARED_WITH = accts.SHARED_WITH,
            ACCOUNTS.CUSTOMER_CODE = accts.CUSTOMER_CODE,
            ACCOUNTS.CCY_CODE = accts.CCY_CODE,
            ACCOUNTS.BALANCE = accts.BALANCE
    WHEN NOT MATCHED THEN
        INSERT ( ACCOUNT_ID, OPEN_DATE, CONTAINER_CODE, ACCOUNT_CODE, ACCOUNT_TYPE, CONTAINER_OWNER, SHARED_WITH, CUSTOMER_CODE, CCY_CODE, BALANCE )
        VALUES (
            accts.ACCOUNT_ID,
            accts.OPEN_DATE,
            accts.CONTAINER_CODE,
            accts.ACCOUNT_CODE,
            accts.ACCOUNT_TYPE,
            accts.CONTAINER_OWNER,
            accts.SHARED_WITH,
            accts.CUSTOMER_CODE,
            accts.CCY_CODE,
            accts.BALANCE
        )
    LOG ERRORS INTO ERR_ACCOUNTS(v_process_name) REJECT LIMIT UNLIMITED;
    v_count :=  SQL%ROWCOUNT;
    COMMIT;

    dbms_output.put_line(v_count||' rows inserted or updated');

    SELECT count(*) INTO v_err_count FROM ERR_ACCOUNTS;

    IF v_err_count != 0 THEN
        load_ERROR_TABLE_LOG(v_date,v_err_table);
        dbms_output.put_line('Found '||v_err_count||' rows rejected. Check error tables for details.');
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
         dbms_output.put_line('ERROR: Unexpected error occurred...');
         dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END load_ACCOUNTS;
/