create or replace PACKAGE BODY generateDimData AS


    PROCEDURE load_DIM_DATE IS
        BEGIN
        MERGE INTO DIM_DATE USING
            ( SELECT TRUNC(SYSDATE - ROWNUM) rDt
              FROM DUAL CONNECT BY ROWNUM <= trunc(sysdate)-to_date('01.01.1990','DD.MM.YYYY')
            ) dates ON (DIM_DATE.YEAR_MONTH_DAY = to_char(dates.rDt,'YYYYMMDD'))
        WHEN NOT MATCHED THEN
        INSERT (YEAR_MONTH_DAY, DATE_DT, YEAR_MONTH_NBR, YEAR_NUMBER, MONTH_NUMBER, DAY_NUMBER, WEEK_DAY_NAME, IS_BSNS_DATE)
        VALUES (
        to_char(dates.rDt,'YYYYMMDD') ,
        dates.rDt ,
        to_number(to_char(dates.rDt,'YYYYMM')) ,
        to_number(to_char(dates.rDt,'YYYY')) ,
        to_number(to_char(dates.rDt,'MM')) ,
        to_number(to_char(dates.rDt,'DD')) ,
        to_char(dates.rDt,'Day') ,
        CASE WHEN to_char(dates.rDt, 'd') IN (1,7)
                THEN 'N'
                ELSE 'Y'
        END  );
        v_count :=  SQL%ROWCOUNT;
        COMMIT;

        -- SELECT count(*) INTO v_count FROM DIM_DATE;
        dbms_output.put_line(v_count||' rows inserted in DIM_DATE');
    END load_DIM_DATE;


    PROCEDURE load_DIM_CUST_GROUP (in_rows IN NUMBER) IS

        BEGIN
        -- insert rows with the owners of the account containers
        FOR r IN 1..in_rows
        LOOP
            SELECT country_code INTO v_country FROM dim_country
                ORDER BY dbms_random.random
                FETCH FIRST ROW ONLY;

            INSERT INTO DIM_CUST_GROUP (
                 GROUP_ID,
                 OWNER_NAME,
                 COUNTRY_CODE )
            SELECT
                DIM_CUST_GROUP_SEQ.nextval GROUP_ID,
                DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15)))||' '||
                        DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15))) OWNER_NAME,
                v_country COUNTRY_CODE
            FROM DUAL;

            -- 10000 rows commit interval
            IF  mod(r,10000) = 0 THEN
              COMMIT;
            END IF;
        END LOOP;
        COMMIT;

        SELECT count(*) INTO v_count FROM DIM_CUST_GROUP;
        dbms_output.put_line(v_count||' rows inserted in DIM_CUST_GROUP');
    END load_DIM_CUST_GROUP;


    PROCEDURE load_DIM_CUSTOMER (in_rows IN NUMBER) IS

        BEGIN
        -- insert main customers, which are present in the group and own the main account (container)
        FOR r IN (SELECT group_id, owner_name, country_code, row_number() over (order by group_id) rNr FROM dim_cust_group)
        LOOP

            SELECT DIM_CUSTOMER_SEQ.nextval INTO v_seq FROM dual;

            INSERT INTO DIM_CUSTOMER (
              CUSTOMER_ID,
              CUSTOMER_CODE,
              CUSTOMER_NAME,
              CUSTOMER_SURNAME,
              GROUP_ID,
              COUNTRY_CODE,
              IS_GROUP_OWNER,
              BIRTHDAY,
              SOCIAL_NUMBER
            )
            SELECT
               v_seq CUSTOMER_ID,
               v_seq||substr(upper(substr(r.owner_name,1,instr(r.owner_name,' ')-1)),1,4) CUSTOMER_CODE,
               substr(r.owner_name,1,instr(r.owner_name,' ')-1) CUSTOMER_NAME,
               substr(r.owner_name,instr(r.owner_name,' ')+1) CUSTOMER_SURNAME,
               r.group_id GROUP_ID,
               r.country_code COUNTRY_CODE,
               'Y' IS_GROUP_OWNER,
               to_date('1950-01-01', 'yyyy-mm-dd')+trunc(dbms_random.value(1,trunc(sysdate-to_date('1950-01-01', 'yyyy-mm-dd'))))  BIRTHDAY,
               substr(v_seq||DBMS_RANDOM.STRING('X',7),1,8) SOCIAL_NUMBER
            FROM DUAL;

            IF  mod(r.rNr,10000) = 0 THEN
              COMMIT;
            END IF;

        END LOOP;
        COMMIT;

        -- insert additional customers
        FOR r IN 1..in_rows
        LOOP

            SELECT group_id,country_code INTO v_group,v_country FROM dim_cust_group
                ORDER BY dbms_random.random
                FETCH FIRST ROW ONLY;

            SELECT DIM_CUSTOMER_SEQ.nextval INTO v_seq FROM dual;

            SELECT DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15))) INTO v_name FROM DUAL;
            SELECT DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15))) INTO v_surname FROM DUAL;

            INSERT INTO DIM_CUSTOMER (
              CUSTOMER_ID,
              CUSTOMER_CODE,
              CUSTOMER_NAME,
              CUSTOMER_SURNAME,
              GROUP_ID,
              COUNTRY_CODE,
              IS_GROUP_OWNER,
              BIRTHDAY,
              SOCIAL_NUMBER
            )
            SELECT
               v_seq CUSTOMER_ID,
               v_seq||substr(upper(v_name),1,4) CUSTOMER_CODE,
               v_name CUSTOMER_NAME,
               v_surname CUSTOMER_SURNAME,
               v_group GROUP_ID,
               v_country COUNTRY_CODE,
               'N' IS_GROUP_OWNER,
               to_date('1950-01-01', 'yyyy-mm-dd')+trunc(dbms_random.value(1,trunc(sysdate-to_date('1950-01-01', 'yyyy-mm-dd'))))  BIRTHDAY,
               substr(v_seq||DBMS_RANDOM.STRING('X',7),1,8) SOCIAL_NUMBER
            FROM DUAL;

            -- 10000 rows commit interval
            IF  mod(r,10000) = 0 THEN
              COMMIT;
            END IF;
        END LOOP;
        COMMIT;


        SELECT count(*) INTO v_count FROM DIM_CUSTOMER;
        dbms_output.put_line(v_count||' rows inserted in DIM_CUSTOMER');
    END load_DIM_CUSTOMER;

       PROCEDURE load_DIM_ACCOUNT (in_rows IN NUMBER) IS

    BEGIN

      -- insert rows of the main customers with current account, which owns the containers
        INSERT INTO DIM_ACCOUNT (
          ACCOUNT_ID,
          CONTAINER_CODE,
          ACCOUNT_CODE,
          ACCOUNT_TYPE,
          CUSTOMER_ID,
          ACCOUNT_CCY_CODE,
          IS_GROUP_SHARED,
          BALANCE,
          OPEN_DATE
        )
        SELECT
          DIM_ACCOUNT_SEQ.nextval AS ACCOUNT_ID,
          substr(DIM_ACCOUNT_SEQ.nextval||DBMS_RANDOM.STRING('X',9),1,10) AS CONTAINER_CODE,
          substr(DIM_ACCOUNT_SEQ.nextval||DBMS_RANDOM.STRING('X',9),1,10) AS ACCOUNT_CODE,
          'CURRENT ACCOUNT' AS ACCOUNT_TYPE,
          (SELECT CUSTOMER_ID FROM DIM_CUSTOMER WHERE upper(CUSTOMER_NAME||' '||CUSTOMER_SURNAME)=upper(DIM_CUST_GROUP.owner_name) ) AS CUSTOMER_ID,
          CURRENCY AS ACCOUNT_CCY_CODE,
          decode(trunc(dbms_random.value(0,2)),0,'Y',1,'N') AS IS_GROUP_SHARED,
          to_number(TRUNC(DBMS_RANDOM.VALUE(1,10000000),2),9999999999.99) AS BALANCE,
          (SELECT TRUNC(SYSDATE - ROWNUM) rDt
              FROM DUAL CONNECT BY ROWNUM <= trunc(sysdate)-add_months(sysdate,-1)
              order by dbms_random.value
              FETCH FIRST ROW ONLY ) OPEN_DATE
        FROM DIM_CUST_GROUP
        JOIN DIM_COUNTRY ON DIM_CUST_GROUP.COUNTRY_CODE=dim_country.country_code;
        COMMIT;

        -- insert rows of the rest of the customers with current account
        INSERT INTO DIM_ACCOUNT (
          ACCOUNT_ID,
          CONTAINER_CODE,
          ACCOUNT_CODE,
          ACCOUNT_TYPE,
          CUSTOMER_ID,
          ACCOUNT_CCY_CODE,
          IS_GROUP_SHARED,
          BALANCE,
          OPEN_DATE
        )
        WITH tmp_with AS (
        SELECT
          'CURRENT ACCOUNT' AS ACCOUNT_TYPE,
          CUSTOMER_ID AS CUSTOMER_ID,
          CURRENCY AS ACCOUNT_CCY_CODE,
          decode(trunc(dbms_random.value(0,2)),0,'Y',1,'N') AS IS_GROUP_SHARED,
          to_number(TRUNC(DBMS_RANDOM.VALUE(1,10000000),2),9999999999.99) AS BALANCE,
          group_id,
          owner_name,
          customer_name,
          customer_surname,
          last_value(container_code IGNORE NULLS) over (order by group_id)  container_code
        FROM DIM_CUSTOMER JOIN DIM_CUST_GROUP USING(group_id)
        JOIN DIM_COUNTRY ON DIM_CUSTOMER.COUNTRY_CODE=dim_country.country_code
        LEFT JOIN DIM_ACCOUNT USING(CUSTOMER_ID)
        )
        SELECT
        DIM_ACCOUNT_SEQ.nextval AS ACCOUNT_ID,
        CONTAINER_CODE AS CONTAINER_CODE,
        substr(DIM_ACCOUNT_SEQ.nextval||DBMS_RANDOM.STRING('X',9),1,10) AS ACCOUNT_CODE,
        ACCOUNT_TYPE AS ACCOUNT_TYPE,
        CUSTOMER_ID AS CUSTOMER_ID,
        ACCOUNT_CCY_CODE AS ACCOUNT_CCY_CODE,
        IS_GROUP_SHARED AS IS_GROUP_SHARED,
        BALANCE AS BALANCE,
        (SELECT TRUNC(SYSDATE - ROWNUM) rDt
              FROM DUAL CONNECT BY ROWNUM <= trunc(sysdate)-add_months(sysdate,-1)
              order by dbms_random.value
              FETCH FIRST ROW ONLY ) OPEN_DATE
        FROM tmp_with JOIN DIM_CUSTOMER USING(CUSTOMER_ID)
        WHERE CUSTOMER_ID NOT IN (SELECT CUSTOMER_ID FROM DIM_ACCOUNT);
        COMMIT;

        -- add other accounts diffrent than current account
        FOR r IN 1..in_rows
        LOOP

          SELECT container_code, customer_id INTO v_container, v_customerId
          FROM dim_account
          ORDER BY dbms_random.random
          FETCH FIRST ROW ONLY;

          SELECT currency_code INTO v_currency
          FROM dim_currency
          ORDER BY dbms_random.random
          FETCH FIRST ROW ONLY;

          INSERT INTO DIM_ACCOUNT (
          ACCOUNT_ID,
          CONTAINER_CODE,
          ACCOUNT_CODE,
          ACCOUNT_TYPE,
          CUSTOMER_ID,
          ACCOUNT_CCY_CODE,
          IS_GROUP_SHARED,
          BALANCE,
          OPEN_DATE
          )
          SELECT
            DIM_ACCOUNT_SEQ.nextval AS ACCOUNT_ID,
            v_container AS CONTAINER_CODE,
            substr(DIM_ACCOUNT_SEQ.nextval||DBMS_RANDOM.STRING('X',9),1,10) AS ACCOUNT_CODE,
            (SELECT column_value FROM TABLE(generateDimData.f_account_types) ORDER BY dbms_random.value FETCH FIRST ROW ONLY) AS ACCOUNT_TYPE,
            v_customerId AS CUSTOMER_ID,
            v_currency AS ACCOUNT_CCY_CODE,
            decode(trunc(dbms_random.value(0,2)),0,'Y',1,'N') AS IS_GROUP_SHARED,
            to_number(TRUNC(DBMS_RANDOM.VALUE(1,10000000),2),9999999999.99) AS BALANCE,
            (SELECT TRUNC(SYSDATE - ROWNUM) rDt
              FROM DUAL CONNECT BY ROWNUM <= trunc(sysdate)-add_months(sysdate,-1)
              order by dbms_random.value
              FETCH FIRST ROW ONLY ) OPEN_DATE
          FROM dual;

        END LOOP;

        SELECT count(*) INTO v_count FROM DIM_ACCOUNT;
        dbms_output.put_line(v_count||' rows inserted in DIM_ACCOUNT');

    END load_DIM_ACCOUNT;



    FUNCTION f_account_types RETURN TVARCHAR PIPELINED
        IS
            BEGIN
            FOR r in v_account_types.first..v_account_types.last
            LOOP
               PIPE ROW(v_account_types(r));
            END LOOP;
        RETURN;
    END f_account_types;

END generateDimData;
/