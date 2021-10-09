DECLARE
v_user VARCHAR2(30 CHAR) := 'SABDUSER';
createTbl VARCHAR(4000 CHAR);
wrongUser EXCEPTION;
tbl_exist EXCEPTION;

PRAGMA EXCEPTION_INIT(tbl_exist, -955);

BEGIN
  IF USER = v_user THEN

    createTbl := 'CREATE TABLE CUSTOMERS (
      CUSTOMER_ID NUMBER,
      CUSTOMER_CODE VARCHAR2(255 CHAR),
      CUSTOMER_NAME VARCHAR2(255 CHAR),
      CUSTOMER_SURNAME VARCHAR2(255 CHAR),
      BIRTHDAY DATE,
      SOCIAL_NUMBER VARCHAR2(255 CHAR),
      GROUP_OWNER VARCHAR2(255 CHAR),
      COUNTRY VARCHAR2(255 CHAR),
      CONSTRAINT CUSTOMER_PK PRIMARY KEY(CUSTOMER_ID),
      CONSTRAINT CUSTOMER_UNQ UNIQUE(CUSTOMER_CODE)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table CUSTOMERS created');

    DBMS_ERRLOG.CREATE_ERROR_LOG('CUSTOMERS','ERR_CUSTOMERS');
    dbms_output.put_line('Table ERR_CUSTOMERS created');

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