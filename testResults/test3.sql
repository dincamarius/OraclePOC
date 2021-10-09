define adminSABD='SABDADM'
define userSABD='SABDUSER'
define passAdmSABD='SABDADM'
define passUserSABD='SABDUSER'

connect &&adminSABD/&&passAdmSABD
SET serveroutput on

EXECUTE dbms_output.put_line(chr(10));
EXECUTE dbms_output.put_line('Connected user is '||USER);

ALTER TABLE fact_transactions MODIFY
PARTITION BY RANGE (tran_date) INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(PARTITION tran_date_min VALUES LESS THAN (TO_DATE('2010-01-01', 'YYYY-MM-DD')));

ALTER TABLE fact_day_rates MODIFY PARTITION BY LIST (from_ccy) AUTOMATIC (PARTITION p_default VALUES ('EUR')) ONLINE;




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

explain plan for
SELECT
    TRANSACTIONS_SEQ.nextval TRAN_KEY,
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
    LEFT JOIN dim_date dd ON ft.date_key=dd.year_month_day
    WHERE ft.tran_date BETWEEN to_date('05.01.2020','DD.MM.YYYY') AND to_date('05.01.2020','DD.MM.YYYY');   
    
    
    
    SELECT * FROM TABLE(dbms_xplan.display);

    begin
        utils.initialize('<load customers>');
        load_customers;
        utils.show_results('<load customers>');

        utils.initialize('<load accounts>');
        load_accounts;
        utils.show_results('<load accounts>');
    end;
    /

    begin
        EXECUTE IMMEDIATE 'TRUNCATE TABLE TRANSACTIONS';
        utils.initialize('<load transactions>');
        load_transactions(to_date('05.01.2020','DD.MM.YYYY'),to_date('06.01.2020','DD.MM.YYYY'));
        utils.show_results('<load transactions>');
    end;
    /

EXECUTE dbms_output.put_line('FINISHED TEST3');