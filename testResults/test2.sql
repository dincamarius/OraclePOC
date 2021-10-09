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


CREATE OR REPLACE TYPE CUST_GROUP_OB AS OBJECT (

    GROUP_ID NUMBER,
    OWNER_NAME VARCHAR2(255),
    COUNTRY_CODE VARCHAR2(3)

);
/

CREATE OR REPLACE TYPE CUST_GROUP_NT AS TABLE OF CUST_GROUP_OB;
/


CREATE OR REPLACE FUNCTION f_custGroup_pl RETURN CUST_GROUP_NT PIPELINED
IS
    v_country VARCHAR2(3);
    out_rec CUST_GROUP_OB := CUST_GROUP_OB(NULL,NULL,NULL);

    BEGIN
    LOOP
        SELECT country_code INTO v_country FROM dim_country
        ORDER BY dbms_random.random
        FETCH FIRST ROW ONLY;

        out_rec.GROUP_ID := TEST1_SEQ.nextval;
        out_rec.OWNER_NAME := DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15)))||' '||DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15)));
        out_rec.COUNTRY_CODE := v_country;

        PIPE ROW(out_rec);
    END LOOP;
RETURN;
END f_custGroup_pl;
/



CREATE OR REPLACE FUNCTION f_custGroup_NOpl(in_rows IN NUMBER) RETURN CUST_GROUP_NT
IS
    v_country VARCHAR2(3);
    out_rec CUST_GROUP_NT := CUST_GROUP_NT();

    BEGIN
    FOR r in 1..in_rows
    LOOP

        SELECT country_code INTO v_country FROM dim_country
        ORDER BY dbms_random.random
        FETCH FIRST ROW ONLY;

        out_rec.EXTEND;
        out_rec (out_rec.LAST) :=
            CUST_GROUP_OB(
                            TEST1_SEQ.nextval,
                            DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15)))||' '||DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('L', TRUNC(DBMS_RANDOM.VALUE(5,15))),
                            v_country
                        );

    END LOOP;
RETURN out_rec;
END f_custGroup_NOpl;
/


CREATE OR REPLACE PROCEDURE run_test2(in_rows IN NUMBER) IS
BEGIN
    utils.initialize('<simple table function>');
    INSERT INTO TEST1 SELECT * FROM TABLE(f_custGroup_NOpl(in_rows));
    COMMIT;
    utils.show_results('<simple table function>');

    utils.initialize('<pipelined function>');
    INSERT INTO TEST1 SELECT * FROM TABLE(f_custGroup_pl) where rownum <=in_rows ;
    COMMIT;
    utils.show_results('<pipelined function>');
END run_test2;
/

EXECUTE dbms_output.put_line('Running test for 10 000 rows...');
execute run_test2(10000);

EXECUTE dbms_output.put_line('FINISHED TEST2');