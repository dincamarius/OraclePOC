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

    createTbl := 'CREATE TABLE DIM_COUNTRY (
      COUNTRY_CODE VARCHAR2(5 CHAR),
      COUNTRY_NAME VARCHAR2(255 CHAR),
      CONTINENT VARCHAR2(255 CHAR),
      REGION VARCHAR2(255 CHAR),
      CURRENCY VARCHAR2(10 CHAR),
      CONSTRAINT DIM_CURRENCY_FK FOREIGN KEY(CURRENCY) REFERENCES DIM_CURRENCY(CURRENCY_CODE),
      CONSTRAINT DIM_COUNTRY_PK PRIMARY KEY(COUNTRY_CODE)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table DIM_COUNTRY created');

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
      dbms_output.put_line('TODO: Create table DIM_CURRENCY first.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/
