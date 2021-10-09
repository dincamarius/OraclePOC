
DECLARE
v_user VARCHAR2(30 CHAR) := 'SABDUSER';
createTbl VARCHAR(4000 CHAR);
wrongUser EXCEPTION;
tbl_exist EXCEPTION;

PRAGMA EXCEPTION_INIT(tbl_exist, -955);

BEGIN
  IF USER = v_user THEN

    createTbl := 'CREATE TABLE ACCOUNTS(
      ACCOUNT_ID NUMBER,
      CONTAINER_CODE VARCHAR2(255 CHAR),
      ACCOUNT_CODE VARCHAR2(255 CHAR),
      ACCOUNT_TYPE VARCHAR2(255 CHAR),
      CONTAINER_OWNER VARCHAR2(255 CHAR),
      SHARED_WITH VARCHAR2(255 CHAR),
      CUSTOMER_CODE VARCHAR2(255 CHAR),
      CCY_CODE  VARCHAR2(10 CHAR),
      BALANCE NUMBER(22,2),
      OPEN_DATE DATE DEFAULT trunc(SYSDATE),
      CONSTRAINT ACCOUNT_PK PRIMARY KEY(ACCOUNT_ID),
      CONSTRAINT ACCOUNT_UNQ UNIQUE (CONTAINER_CODE, ACCOUNT_CODE, CUSTOMER_CODE)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table ACCOUNTS created');

    DBMS_ERRLOG.CREATE_ERROR_LOG('ACCOUNTS','ERR_ACCOUNTS');
    dbms_output.put_line('Table ERR_ACCOUNTS created');

  ELSE
    RAISE wrongUser;
  END IF;

EXCEPTION
    WHEN wrongUser THEN
    dbms_output.put_line('ERROR: Connected user is not '||v_user);

    WHEN tbl_exist THEN
      dbms_output.put_line('ERROR: Table already exist');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/


