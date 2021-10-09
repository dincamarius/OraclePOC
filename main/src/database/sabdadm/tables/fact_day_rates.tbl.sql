DECLARE
v_adm_user VARCHAR2(30 CHAR) := 'SABDADM';
createTbl VARCHAR(4000 CHAR);
wrongUser EXCEPTION;
tbl_exist EXCEPTION;
fk_exception EXCEPTION;

PRAGMA EXCEPTION_INIT(tbl_exist, -955);
PRAGMA EXCEPTION_INIT(fk_exception, -942);

BEGIN
  IF USER = v_adm_user THEN

    createTbl := 'CREATE TABLE FACT_DAY_RATES (
      DATE_KEY VARCHAR2(8 CHAR),
      DATE_DT DATE,
      FROM_CCY VARCHAR2(10 CHAR),
      TO_CCY VARCHAR2(10 CHAR),
      EXCHANGE_RATE NUMBER(10,2),
      FOREIGN KEY(FROM_CCY) REFERENCES DIM_CURRENCY(CURRENCY_CODE),
      FOREIGN KEY(TO_CCY) REFERENCES DIM_CURRENCY(CURRENCY_CODE),
      FOREIGN KEY(DATE_KEY) REFERENCES DIM_DATE(YEAR_MONTH_DAY)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table FACT_DAY_RATES created');

  ELSE
    RAISE wrongUser;
  END IF;

EXCEPTION
    WHEN wrongUser THEN
    dbms_output.put_line('ERROR: Connected user is not '||v_adm_user);

    WHEN tbl_exist THEN
      dbms_output.put_line('ERROR: Table already exist');

    WHEN fk_exception THEN
      dbms_output.put_line('ERROR: Cannot create foreign key, referenced table does not exist.');
      dbms_output.put_line('TODO: Create tables DIM_CURRENCY AND DIM_DATE first.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/

