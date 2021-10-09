define adminSABD='SABDADM'
define passAdmSABD='SABDADM'

connect &&adminSABD/&&passAdmSABD
SET serveroutput on
EXECUTE dbms_output.put_line(chr(10));
EXECUTE dbms_output.put_line('Connected user is '||USER);

SET pagesize 5000
SET long 5000
SET pages 500
SET linesize 300
SET echo on
SET serveroutput on
--WHENEVER SQLERROR EXIT


CREATE TABLE TEST1(
    GROUP_ID NUMBER,
    OWNER_NAME VARCHAR2(255),
    COUNTRY_CODE VARCHAR2(3)
);

CREATE SEQUENCE TEST1_SEQ MINVALUE 1 MAXVALUE 999999999999999999999999999 START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE PROCEDURE run_test1(in_rows IN NUMBER) IS

CURSOR c_data IS
    SELECT  TEST1_SEQ.nextval,
     DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15)))||' '||DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15))),
     DBMS_RANDOM.STRING('U', 3)
     FROM DUAL connect by level <= in_rows;

     TYPE data_nt IS TABLE OF c_data%ROWTYPE;
     l_data data_nt;

     v_cntFors NUMBER := 0;

BEGIN
        utils.initialize('<bulk processing>');
        OPEN c_data;
        v_cntFors :=0;
        LOOP
            FETCH c_data BULK COLLECT INTO l_data;
            FORALL r IN l_data.FIRST..l_data.LAST
                INSERT INTO TEST1 VALUES l_data(r);
            COMMIT;
            v_cntFors := v_cntFors+1;
            EXIT WHEN c_data%NOTFOUND;
        END LOOP;
        CLOSE c_data;
        dbms_output.put_line('Executed loop for '||v_cntFors||' times');
        utils.show_results('<bulk processing>');

        utils.initialize('<explicit cursor>');
        v_cntFors :=0;
        FOR r IN c_data
        LOOP
            INSERT INTO TEST1 VALUES r;
            COMMIT;
            v_cntFors := v_cntFors+1;
        END LOOP;
        dbms_output.put_line('Executed loop for '||v_cntFors||' times');
        utils.show_results('<explicit cursor>');

        utils.initialize('<implicit cursor>');
        v_cntFors :=0;
        FOR r IN (SELECT  TEST1_SEQ.nextval A,
             DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15)))||' '||DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15))) B,
             DBMS_RANDOM.STRING('U', 3) C
             FROM DUAL connect by level <= in_rows)
        LOOP
            INSERT INTO TEST1 VALUES(r.A,r.B,r.C);
            COMMIT;
            v_cntFors := v_cntFors+1;
        END LOOP;
        dbms_output.put_line('Executed loop for '||v_cntFors||' times');
        utils.show_results('<implicit cursor>');


END run_test1;
/

EXECUTE dbms_output.put_line('Running test for 100 000 rows on an object table with 3 columns(1 - number, 2 - varchar2)...');
EXECUTE run_test1(100000);

EXECUTE dbms_output.put_line('FINISHED TEST1');