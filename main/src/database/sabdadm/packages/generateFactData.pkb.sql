CREATE OR REPLACE PACKAGE BODY generateFactData AS


PROCEDURE load_FACT_DAY_RATES(mnt_in IN NUMBER DEFAULT 1) IS

BEGIN

    dbms_output.put_line('Generating rates for all currencies, for last '||mnt_in||' months...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE FACT_DAY_RATES';

    INSERT INTO FACT_DAY_RATES (
        DATE_KEY,
        DATE_DT,
        FROM_CCY,
        TO_CCY,
        EXCHANGE_RATE
    )
     WITH dates AS (
            SELECT YEAR_MONTH_DAY DATE_KEY,
            DATE_DT DATE_DT
            FROM DIM_DATE
            WHERE DATE_DT >= ADD_MONTHS(v_maxDate, -(mnt_in))
        ),
        ccys AS (
        SELECT
        dc1.currency_code FROM_CCY,
        dc2.currency_code TO_CCY
        FROM dim_currency dc1 CROSS JOIN dim_currency dc2
        WHERE dc1.currency_code != ' ' AND dc2.currency_code != ' '
        )
        SELECT
            DATE_KEY,
            DATE_DT,
            FROM_CCY,
            TO_CCY,
            CASE
                WHEN FROM_CCY=TO_CCY THEN 1
                ELSE trunc(dbms_random.value(0,4))+0.01
            END AS EXCHANGE_RATE
        FROM dates CROSS JOIN ccys;
        v_count := SQL%ROWCOUNT;
     COMMIT;

     dbms_output.put_line(v_count||' rows inserted in FACT_DAY_RATES');

END load_FACT_DAY_RATES;


-- this procedure is used to update fact_day_rates like:
-- date_key - EUR - USD - randomNumber
-- date_key - USD - EUR - 1/randomNumber
PROCEDURE update_FACT_DAY_RATES( nr_rows IN NUMBER) IS

v_rate NUMBER;
v_check NUMBER;
j NUMBER := 0;
v_time NUMBER ;

CURSOR v_cursor IS
      SELECT
        date_key,
        from_ccy,
        to_ccy
      FROM fact_day_rates WHERE exchange_rate IS NULL AND ROWNUM <= nr_rows;

TYPE rates_nt IS TABLE OF v_cursor%rowtype INDEX BY PLS_INTEGER;
l_rates rates_nt;

BEGIN

  OPEN v_cursor;
  LOOP
    v_time := dbms_utility.get_time;
    j := j+1;
    dbms_output.put_line('Start fetch index '||j);

    FETCH v_cursor BULK COLLECT INTO l_rates LIMIT bacth_limit;

    FOR r IN 1..l_rates.count
    LOOP

        v_rate := trunc(dbms_random.value(0,4))+0.01;

        SELECT exchange_rate INTO v_check FROM fact_Day_rates WHERE date_key=l_rates(r).date_key AND from_ccy=l_rates(r).from_ccy AND to_ccy=l_rates(r).to_ccy;

        IF v_check IS NULL THEN
          UPDATE fact_day_rates SET exchange_rate=v_rate
          WHERE date_key=l_rates(r).date_key AND from_ccy=l_rates(r).from_ccy AND to_ccy=l_rates(r).to_ccy;

          UPDATE fact_day_rates SET exchange_rate=round(1/v_rate,2)
          WHERE date_key=l_rates(r).date_key AND from_ccy=l_rates(r).to_ccy AND to_ccy=l_rates(r).from_ccy;

          COMMIT;
        END IF;
    END LOOP;
    EXIT WHEN l_rates.COUNT < bacth_limit;
    dbms_output.put_line('End fetch index '||j||' in '||(dbms_utility.get_time-v_time)/100||' seconds');
  END LOOP;
  CLOSE v_cursor;
END update_FACT_DAY_RATES;



PROCEDURE load_FACT_TRANSACTIONS(mnt_in IN NUMBER DEFAULT 1) IS

  CURSOR c_dates IS
    SELECT
        YEAR_MONTH_DAY,
        DATE_DT
    FROM DIM_DATE WHERE DATE_DT >= ADD_MONTHS(v_maxDate, -(mnt_in));

  TYPE dates_nt IS TABLE OF c_dates%rowtype INDEX BY PLS_INTEGER;
  l_dates dates_nt;
  v_rows NUMBER := 0;

BEGIN

    dbms_output.put_line('Generating random transactions for last '||mnt_in||' months...');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE FACT_TRANSACTIONS';

  OPEN c_dates;
  LOOP
      FETCH c_dates BULK COLLECT INTO l_dates;

      FOR l_row IN 1..l_dates.COUNT
      LOOP
        -- insert 1000 random transactions
        INSERT INTO FACT_TRANSACTIONS(
          DATE_KEY,
          TRAN_DATE,
          SOURCE_ACCOUNT,
          DEST_ACCOUNT,
          OPERATION_CODE,
          AMOUNT_IN_LCL_CCY
        )
        SELECT
          l_dates(l_row).YEAR_MONTH_DAY DATE_KEY,
          l_dates(l_row).DATE_DT DATE_DT,
          CASE WHEN OPERATION_CODE = 'DEPOSIT'
              THEN  NULL
              ELSE SRC.ACCOUNT_ID
          END SOURCE_ACCOUNT,
          CASE WHEN OPERATION_CODE IN ('BANK TRANSFER', 'DEPOSIT')
              THEN  DEST.ACCOUNT_ID
              ELSE NULL
          END DEST_ACCOUNT,
          OPERATION_CODE OPERATION_CODE,
          trunc(dbms_random.value(0,10000),2) AMOUNT_IN_LCL_CCY
       FROM DIM_ACCOUNT SRC CROSS JOIN DIM_ACCOUNT DEST
          JOIN DIM_OPERATION OP ON SRC.ACCOUNT_TYPE = OP.ACCT_TYPE
       ORDER BY dbms_random.value
       FETCH FIRST 1000 ROWS ONLY;
       v_rows := v_rows+SQL%ROWCOUNT;
       COMMIT;

       -- insert 100 bank transfer transactions between accounts of same customer
       INSERT INTO FACT_TRANSACTIONS(
          DATE_KEY,
          TRAN_DATE,
          SOURCE_ACCOUNT,
          DEST_ACCOUNT,
          OPERATION_CODE,
          AMOUNT_IN_LCL_CCY
        )
       SELECT
          l_dates(l_row).YEAR_MONTH_DAY DATE_KEY,
          l_dates(l_row).DATE_DT DATE_DT,
          SRC.ACCOUNT_ID SOURCE_ACCOUNT,
          DEST.ACCOUNT_ID DEST_ACCOUNT,
          OPERATION_CODE OPERATION_CODE,
          trunc(dbms_random.value(0,10000),2) AMOUNT_IN_LCL_CCY
       FROM DIM_ACCOUNT SRC JOIN DIM_ACCOUNT DEST ON SRC.CUSTOMER_ID=DEST.CUSTOMER_ID
          JOIN DIM_OPERATION OP ON SRC.ACCOUNT_TYPE = OP.ACCT_TYPE
       WHERE SRC.ACCOUNT_TYPE != 'INVESTMENT ACCOUNT' AND DEST.ACCOUNT_TYPE = 'INVESTMENT ACCOUNT' AND OPERATION_CODE='BANK TRANSFER'
       ORDER BY dbms_random.value
       FETCH FIRST 100 ROWS ONLY;
       v_rows := v_rows+SQL%ROWCOUNT;
       COMMIT;

      END LOOP;
       EXIT WHEN c_dates%NOTFOUND;
  END LOOP;
  CLOSE c_dates;

  dbms_output.put_line(v_rows||' rows inserted in FACT_TRANSACTIONS');
END load_FACT_TRANSACTIONS;


-- functions
FUNCTION f_get_TRANSACTIONS(mnt_in IN NUMBER DEFAULT 1) RETURN trans_nt IS

    CURSOR c_trans(nr_mnt NUMBER) IS
     WITH dates AS (
        SELECT
            YEAR_MONTH_DAY,
            DATE_DT
        FROM DIM_DATE WHERE DATE_DT >= ADD_MONTHS(v_maxDate, -(nr_mnt))
        )
        ,dl AS (SELECT 1 r FROM DUAL UNION ALL SELECT 2 FROM DUAL )
        SELECT
        YEAR_MONTH_DAY DATE_KEY,
        DATE_DT DATE_DT,
        CASE WHEN decode(dl.r,1,OPERATION_CODE,'DEPOSIT') = 'DEPOSIT'
              THEN  NULL
              ELSE SRC.ACCOUNT_ID
          END SOURCE_ACCOUNT,
          CASE WHEN decode(dl.r,1,OPERATION_CODE,'DEPOSIT') IN ('BANK TRANSFER', 'DEPOSIT')
              THEN  DEST.ACCOUNT_ID
              ELSE NULL
          END DEST_ACCOUNT,
          OPERATION_CODE OPERATION_CODE,
          trunc(dbms_random.value(0,10000),2) AMOUNT_IN_LCL_CCY
       FROM dl CROSS JOIN DIM_ACCOUNT SRC
       JOIN DIM_OPERATION OP ON SRC.ACCOUNT_TYPE = OP.ACCT_TYPE
       JOIN DIM_ACCOUNT DEST ON decode(dl.r,2,SRC.CUSTOMER_ID,1)=decode(dl.r,2,DEST.CUSTOMER_ID,1)
       CROSS JOIN dates
       WHERE decode(dl.r,2,SRC.ACCOUNT_TYPE,' ') != 'INVESTMENT ACCOUNT' AND decode(dl.r,2,DEST.ACCOUNT_TYPE,'INVESTMENT ACCOUNT') = 'INVESTMENT ACCOUNT'
        AND decode(dl.r,2,OPERATION_CODE,'BANK TRANSFER')='BANK TRANSFER'
       -- ORDER BY dbms_random.value
       ;

    l_trans trans_nt;
    l_trans2 trans_nt := trans_nt();

BEGIN

    OPEN c_trans(mnt_in);
    LOOP
        FETCH c_trans BULK COLLECT INTO l_trans LIMIT bacth_limit;
        EXIT WHEN l_trans.COUNT = 0;
        LOOP
           FOR r in 1..l_trans.count
            LOOP
               l_trans2.EXTEND;
               l_trans2(l_trans2.LAST) := l_trans(r);
            END LOOP;
        END LOOP;
    END LOOP;
    RETURN l_trans2;
END f_get_TRANSACTIONS;


FUNCTION f_get_TRANSACTIONS_PL(mnt_in IN NUMBER DEFAULT 1) RETURN trans_nt PIPELINED IS

    CURSOR c_trans(nr_mnt NUMBER) IS
     WITH dates AS (
        SELECT
            YEAR_MONTH_DAY,
            DATE_DT
        FROM DIM_DATE WHERE DATE_DT >= ADD_MONTHS(v_maxDate, -(nr_mnt))
        )
        ,dl AS (SELECT 1 r FROM DUAL UNION ALL SELECT 2 FROM DUAL )
        SELECT
        YEAR_MONTH_DAY DATE_KEY,
        DATE_DT DATE_DT,
        CASE WHEN decode(dl.r,1,OPERATION_CODE,'DEPOSIT') = 'DEPOSIT'
              THEN  NULL
              ELSE SRC.ACCOUNT_ID
          END SOURCE_ACCOUNT,
          CASE WHEN decode(dl.r,1,OPERATION_CODE,'DEPOSIT') IN ('BANK TRANSFER', 'DEPOSIT')
              THEN  DEST.ACCOUNT_ID
              ELSE NULL
          END DEST_ACCOUNT,
          OPERATION_CODE OPERATION_CODE,
          trunc(dbms_random.value(0,10000),2) AMOUNT_IN_LCL_CCY
       FROM dl CROSS JOIN DIM_ACCOUNT SRC
       JOIN DIM_OPERATION OP ON SRC.ACCOUNT_TYPE = OP.ACCT_TYPE
       JOIN DIM_ACCOUNT DEST ON decode(dl.r,2,SRC.CUSTOMER_ID,1)=decode(dl.r,2,DEST.CUSTOMER_ID,1)
       CROSS JOIN dates
       WHERE decode(dl.r,2,SRC.ACCOUNT_TYPE,' ') != 'INVESTMENT ACCOUNT' AND decode(dl.r,2,DEST.ACCOUNT_TYPE,'INVESTMENT ACCOUNT') = 'INVESTMENT ACCOUNT'
        AND decode(dl.r,2,OPERATION_CODE,'BANK TRANSFER')='BANK TRANSFER'
       -- ORDER BY dbms_random.value
       ;

    l_trans trans_nt;

BEGIN

    OPEN c_trans(mnt_in);
    LOOP
        FETCH c_trans BULK COLLECT INTO l_trans LIMIT bacth_limit;
        EXIT WHEN l_trans.COUNT = 0;
        FOR r in l_trans.first..l_trans.last
         LOOP
           PIPE ROW(l_trans(r));
         END LOOP;
    END LOOP;
    RETURN;
END f_get_TRANSACTIONS_PL;





FUNCTION f_get_TRANSACTIONS_PL2( c_trans trans_rc) RETURN trans_nt PIPELINED IS

    l_trans trans_nt;
BEGIN

    LOOP
        FETCH c_trans BULK COLLECT INTO l_trans LIMIT bacth_limit;
        EXIT WHEN l_trans.COUNT = 0;
          FOR r in 1..l_trans.COUNT
           LOOP
             PIPE ROW(l_trans(r));
           END LOOP;
        END LOOP;
    RETURN;
END f_get_TRANSACTIONS_PL2;



BEGIN

    SELECT to_date(max(YEAR_MONTH_DAY),'YYYYMMDD') INTO v_maxDate FROM DIM_DATE;

END generateFactData;
/