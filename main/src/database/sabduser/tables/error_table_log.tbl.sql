DECLARE
v_user VARCHAR2(30 CHAR) := 'SABDUSER';
createTbl VARCHAR(4000 CHAR);
wrongUser EXCEPTION;
tbl_exist EXCEPTION;

PRAGMA EXCEPTION_INIT(tbl_exist, -955);

BEGIN
  IF USER = v_user THEN

  createTbl := 'CREATE TABLE ERROR_TABLE_LOG (
    ERROR_DATE DATE DEFAULT trunc(SYSDATE),
    PROCESS_NAME VARCHAR2(255 CHAR),
    ERROR_CODE VARCHAR2(10 CHAR),
    ERROR_MESSAGE VARCHAR2(255 CHAR),
    ROW_IDENTIFIER VARCHAR2(255 CHAR)
  )';

  EXECUTE IMMEDIATE createTbl;
  dbms_output.put_line('Table ERROR_TABLE_LOG created');

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

