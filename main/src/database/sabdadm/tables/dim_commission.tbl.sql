
DECLARE
v_adm_user VARCHAR2(30 CHAR) := 'SABDADM';
createTbl VARCHAR(4000 CHAR);

wrongUser EXCEPTION;
tbl_exist EXCEPTION;

PRAGMA EXCEPTION_INIT(tbl_exist, -955);

BEGIN
  IF USER = v_adm_user THEN

    createTbl := 'CREATE TABLE DIM_COMMISSION(
      COMMISSION_ID NUMBER,
      OPERATION_CODE VARCHAR2(255 CHAR),
      BOUNDARY_CHANGE_COMM NUMBER,
      COMM_PERCENTAGE VARCHAR(50 CHAR),
      CURRENCY_CODE VARCHAR2(3 CHAR),
      CONSTRAINT DIM_COMM_PK PRIMARY KEY(COMMISSION_ID)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table DIM_COMMISSION created');

  ELSE
    RAISE wrongUser;
  END IF;

EXCEPTION
    WHEN wrongUser THEN
    dbms_output.put_line('ERROR: Connected user is not '||v_adm_user);

    WHEN tbl_exist THEN
      dbms_output.put_line('ERROR: Table already exist');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/