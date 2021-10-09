
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

    createTbl := 'CREATE TABLE DIM_ACCOUNT (
      ACCOUNT_ID NUMBER,
      OPEN_DATE DATE DEFAULT trunc(SYSDATE),
      CONTAINER_CODE VARCHAR2(255 CHAR),
      ACCOUNT_CODE VARCHAR2(255 CHAR),
      ACCOUNT_TYPE VARCHAR2(255 CHAR),
      CUSTOMER_ID NUMBER,
      ACCOUNT_CCY_CODE  VARCHAR(10 CHAR),
      IS_GROUP_SHARED VARCHAR2(1) CHECK (IS_GROUP_SHARED IN (''Y'',''N'')),
      BALANCE NUMBER(22,2),
      CONSTRAINT DIM_ACCOUNT_PK PRIMARY KEY(ACCOUNT_ID),
      CONSTRAINT DIM_ACCOUNT_UNQ UNIQUE (CONTAINER_CODE, ACCOUNT_CODE),
      CONSTRAINT DIM_CUST_ACNT_FK FOREIGN KEY(CUSTOMER_ID) REFERENCES DIM_CUSTOMER(CUSTOMER_ID),
      CONSTRAINT DIM_LCL_CURR_FK FOREIGN KEY(ACCOUNT_CCY_CODE) REFERENCES DIM_CURRENCY(CURRENCY_CODE)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table DIM_ACCOUNT created');

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
      dbms_output.put_line('TODO: Create table DIM_COUNTRY first.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/


