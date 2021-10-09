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

    createTbl := 'CREATE TABLE FACT_TRANSACTIONS (
      DATE_KEY VARCHAR2(8 CHAR),
      TRAN_DATE DATE,
      SOURCE_ACCOUNT NUMBER,
      DEST_ACCOUNT NUMBER,
      OPERATION_CODE VARCHAR2(255 CHAR),
      AMOUNT_IN_LCL_CCY NUMBER(22,2),
      FOREIGN KEY(DATE_KEY) REFERENCES DIM_DATE(YEAR_MONTH_DAY),
      FOREIGN KEY(SOURCE_ACCOUNT) REFERENCES DIM_ACCOUNT(ACCOUNT_ID),
      FOREIGN KEY(DEST_ACCOUNT) REFERENCES DIM_ACCOUNT(ACCOUNT_ID)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table FACT_TRANSACTIONS created');

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
      dbms_output.put_line('TODO: Create dimension tables first.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/

