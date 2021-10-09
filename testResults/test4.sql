define userSABD='SABDUSER'
define passUserSABD='SABDUSER'

connect &&userSABD/&&passUserSABD

SET serveroutput on
SET pagesize 5000
SET long 5000
SET pages 500
SET linesize 300
SET echo on
SET serveroutput on
--WHENEVER SQLERROR EXIT

EXECUTE dbms_output.put_line(chr(10));
EXECUTE dbms_output.put_line('Connected user is '||USER);



CREATE MATERIALIZED VIEW tran_mv
     TABLESPACE sabd_tbs
     PARALLEL 4
     BUILD IMMEDIATE
     REFRESH COMPLETE
     ENABLE QUERY REWRITE
     AS
     SELECT
    ft.tran_date TRAN_DATE,
    ft.date_key DATE_KEY,
    dd.is_bsns_date IS_BSNS_DT,
    ft.source_account SOURCE_ACCOUNT_KEY,
    CASE WHEN ft.source_account IS NULL
        THEN NULL
        ELSE (SELECT das.customer_id FROM dim_account das WHERE das.account_id = ft.source_account)
    END SOURCE_CUSTOMER_KEY,
    ft.dest_account TARGET_ACCOUNT_KEY,
    CASE WHEN ft.dest_account IS NULL
        THEN NULL
        ELSE (SELECT dad.customer_id FROM dim_account dad WHERE dad.account_id = ft.dest_account)
    END TARGET_CUSTOMER_KEY,
    'EUR' COMMISSION_CCY,
    CASE WHEN ft.source_account IS NULL
        THEN NULL
        ELSE (SELECT das.account_ccy_code FROM dim_account das WHERE das.account_id = ft.source_account)
    END SOURCE_CCY,
    CASE WHEN ft.dest_account IS NULL
        THEN NULL
        ELSE (SELECT dad.account_ccy_code FROM dim_account dad WHERE dad.account_id = ft.dest_account)
    END TARGET_CCY,
    CASE WHEN ft.source_account IS NULL OR ft.dest_account IS NULL
         THEN 1
         ELSE (SELECT fdr.exchange_rate FROM fact_day_rates fdr WHERE fdr.date_key=ft.date_key
                AND fdr.from_ccy = (SELECT das.account_ccy_code FROM dim_account das WHERE das.account_id = ft.source_account)
                AND fdr.to_ccy = (SELECT dad.account_ccy_code FROM dim_account dad WHERE dad.account_id = ft.dest_account)
                )
    END EXCHANGE_RATE_SRC_TGT,
    CASE WHEN ft.source_account IS NULL
         THEN (SELECT fdr.exchange_rate FROM fact_day_rates fdr WHERE fdr.date_key=ft.date_key
                AND fdr.from_ccy = (SELECT dad.account_ccy_code FROM dim_account dad WHERE dad.account_id = ft.dest_account)
                AND fdr.to_ccy = 'EUR'
                )
         ELSE (SELECT fdr.exchange_rate FROM fact_day_rates fdr WHERE fdr.date_key=ft.date_key
                AND fdr.from_ccy = (SELECT das.account_ccy_code FROM dim_account das WHERE das.account_id = ft.source_account)
                AND fdr.to_ccy = 'EUR'
                )
    END EXCHANGE_RATE_COMM,
    operation_code OPERATION_CODE,
    CASE WHEN ft.source_account IS NULL
        THEN NULL
        ELSE ft.AMOUNT_IN_LCL_CCY
    END AMOUNT_IN_SRC_CCY,
    CASE WHEN ft.source_account IS NULL
        THEN (SELECT (to_number(substr(comm_percentage,1,instr(comm_percentage,'%')-1),99.99)/100)*ft.AMOUNT_IN_LCL_CCY
                FROM dim_commission dc
                WHERE dc.operation_code=ft.operation_code)*(SELECT fdr.exchange_rate FROM fact_day_rates fdr WHERE fdr.date_key=ft.date_key
                                                    AND fdr.from_ccy = (SELECT dad.account_ccy_code FROM dim_account dad WHERE dad.account_id = ft.dest_account)
                                                    AND fdr.to_ccy = 'EUR'
                                                    )
        ELSE (SELECT (to_number(substr(comm_percentage,1,instr(comm_percentage,'%')-1),99.99)/100)*ft.AMOUNT_IN_LCL_CCY
                FROM dim_commission dc
                WHERE dc.operation_code=ft.operation_code)*(SELECT fdr.exchange_rate FROM fact_day_rates fdr WHERE fdr.date_key=ft.date_key
                                                            AND fdr.from_ccy = (SELECT das.account_ccy_code FROM dim_account das WHERE das.account_id = ft.source_account)
                                                            AND fdr.to_ccy = 'EUR'
                                                            )
    END COMMISSION,
    CASE WHEN ft.source_account IS NULL
        THEN ft.AMOUNT_IN_LCL_CCY
        ELSE ft.AMOUNT_IN_LCL_CCY*(CASE WHEN ft.source_account IS NULL OR ft.dest_account IS NULL
                                     THEN 1
                                     ELSE (SELECT fdr.exchange_rate FROM fact_day_rates fdr WHERE fdr.date_key=ft.date_key
                                            AND fdr.from_ccy = (SELECT das.account_ccy_code FROM dim_account das WHERE das.account_id = ft.source_account)
                                            AND fdr.to_ccy = (SELECT dad.account_ccy_code FROM dim_account dad WHERE dad.account_id = ft.dest_account)
                                            )
                                    END)
    END AMOUNT_IN_TGT_CCY
    FROM
    fact_transactions ft
    LEFT JOIN dim_date dd ON ft.date_key=dd.year_month_day;


create or replace PROCEDURE load_TRANSACTIONS_MV(from_dt IN DATE DEFAULT NULL, to_dt IN DATE DEFAULT NULL ) AUTHID DEFINER IS

    v_count NUMBER;
    v_err_count NUMBER := 0;
    v_process_name VARCHAR2(255 CHAR) := 'LOAD_TRANSACTIONS';
    v_err_table VARCHAR2(255) := 'ERR_TRANSACTIONS';
    v_date DATE := trunc(SYSDATE);
    v_from_dt DATE;
    v_to_dt DATE;
    NO_CCY EXCEPTION;
    v_comm_ccy VARCHAR2(3) := 'EUR';
    in_from_dt DATE;
    in_to_dt DATE;


BEGIN

    in_from_dt := from_dt;
    in_to_dt := to_dt;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE ERR_TRANSACTIONS';
    dbms_output.put_line('Start loading TRANSACTIONS table...');

    IF in_from_dt IS NULL AND in_to_dt IS NULL THEN
       dbms_output.put_line('Start full loading TRANSACTIONS table...');
       EXECUTE IMMEDIATE 'TRUNCATE TABLE TRANSACTIONS';
       SELECT min(DATE_DT) INTO v_from_dt FROM DIM_DATE;
       in_from_dt := v_from_dt;
       SELECT max(DATE_DT) INTO v_to_dt FROM DIM_DATE;
       in_to_dt := v_to_dt;
    ELSE
        dbms_output.put_line('Start partial loading TRANSACTIONS table...');
        IF in_from_dt IS NULL THEN
            SELECT min(DATE_DT) INTO v_from_dt FROM DIM_DATE;
            in_from_dt := v_from_dt;
        END IF;
        IF in_to_dt IS NULL THEN
            SELECT max(DATE_DT) INTO v_to_dt FROM DIM_DATE;
            in_to_dt := v_to_dt;
        END IF;

        DELETE FROM TRANSACTIONS WHERE TRAN_DATE BETWEEN in_from_dt AND in_to_dt;
        v_count := SQL%ROWCOUNT;
        COMMIT;
        dbms_output.put_line('Cleaned up '||v_count||' rows from TRANSACTIONS table');
    END IF;

--    FOR r IN ( SELECT FROM_DT,
--                      TO_DT
--                FROM ( SELECT lag(DATE_DT) OVER (ORDER BY DATE_DT) FROM_DT, DATE_DT TO_DT FROM DIM_DATE WHERE IS_BSNS_DATE='Y')
--                WHERE FROM_DT=in_from_dt AND TO_DT=in_to_dt)
--    LOOP
--        null;
--    END LOOP;
--
    INSERT INTO transactions (
        TRAN_DATE,
        DATE_KEY,
        IS_BSNS_DT,
        SOURCE_ACCOUNT_KEY,
        SOURCE_CUSTOMER_KEY,
        TARGET_ACCOUNT_KEY,
        TARGET_CUSTOMER_KEY,
        COMMISSION_CCY,
        SOURCE_CCY,
        TARGET_CCY,
        EXCHANGE_RATE_SRC_TGT,
        EXCHANGE_RATE_COMM,
        OPERATION_CODE,
        AMOUNT_IN_SRC_CCY,
        COMMISSION,
        AMOUNT_IN_TGT_CCY
    )
    SELECT
    TRAN_DATE,
    DATE_KEY,
    IS_BSNS_DT,
    SOURCE_ACCOUNT_KEY,
    SOURCE_CUSTOMER_KEY,
    TARGET_ACCOUNT_KEY,
    TARGET_CUSTOMER_KEY,
    COMMISSION_CCY,
    SOURCE_CCY,
    TARGET_CCY,
    EXCHANGE_RATE_SRC_TGT,
    EXCHANGE_RATE_COMM,
    OPERATION_CODE,
    AMOUNT_IN_SRC_CCY,
    COMMISSION,
    AMOUNT_IN_TGT_CCY
    FROM
    tran_mv ft
    WHERE ft.tran_date BETWEEN in_from_dt AND in_to_dt
    LOG ERRORS INTO ERR_TRANSACTIONS(v_process_name) REJECT LIMIT UNLIMITED;
    v_count :=  SQL%ROWCOUNT;
    COMMIT;

    dbms_output.put_line(v_count||' rows inserted');

    SELECT count(*) INTO v_err_count FROM ERR_TRANSACTIONS;
    IF v_err_count != 0 THEN
        load_ERROR_TABLE_LOG(v_date, v_err_table);
        dbms_output.put_line('Found '||v_err_count||' rows rejected. Check error tables for details.');
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
         dbms_output.put_line('ERROR: Unexpected error occurred...');
         dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END load_TRANSACTIONS_MV;
/


begin
    EXECUTE IMMEDIATE 'TRUNCATE TABLE TRANSACTIONS';
    utils.initialize('<load transactions with mv>');
    load_transactions_mv;
    utils.show_results('<load transactions with mv>');
end;
/

EXECUTE dbms_output.put_line('FINISHED TEST4');