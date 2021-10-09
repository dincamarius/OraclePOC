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

    createTbl := 'CREATE TABLE DIM_CUST_GROUP (
      GROUP_ID NUMBER,
      OWNER_NAME VARCHAR2(255 CHAR),
      COUNTRY_CODE VARCHAR2(5 CHAR),
      CONSTRAINT DIM_CUST_GROUP_PK PRIMARY KEY(GROUP_ID),
      CONSTRAINT DIM_GROUP_COUNTRY_FK FOREIGN KEY(COUNTRY_CODE) REFERENCES DIM_COUNTRY(COUNTRY_CODE)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table DIM_CUST_GROUP created');

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



