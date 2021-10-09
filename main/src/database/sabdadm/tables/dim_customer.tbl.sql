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

    createTbl := 'CREATE TABLE DIM_CUSTOMER (
      CUSTOMER_ID NUMBER,
      CUSTOMER_CODE VARCHAR2(255 CHAR),
      CUSTOMER_NAME VARCHAR2(255 CHAR),
      CUSTOMER_SURNAME VARCHAR2(255 CHAR),
      GROUP_ID NUMBER,
      COUNTRY_CODE VARCHAR2(5 CHAR),
      IS_GROUP_OWNER VARCHAR2(1 CHAR) CHECK (IS_GROUP_OWNER IN (''Y'',''N'')),
      BIRTHDAY DATE,
      SOCIAL_NUMBER VARCHAR2(255 CHAR),
      CONSTRAINT DIM_CUSTOMER_PK PRIMARY KEY(CUSTOMER_ID),
      CONSTRAINT DIM_CUSTOMER_UNQ UNIQUE(CUSTOMER_CODE),
      CONSTRAINT DIM_CUST_GRP_FK FOREIGN KEY(GROUP_ID) REFERENCES DIM_CUST_GROUP(GROUP_ID),
      CONSTRAINT DIM_CUST_CONTRY_FK FOREIGN KEY(COUNTRY_CODE) REFERENCES DIM_COUNTRY(COUNTRY_CODE)
    )';

    EXECUTE IMMEDIATE createTbl;
    dbms_output.put_line('Table DIM_CUSTOMER created');

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
      dbms_output.put_line('TODO: Create table DIM_CUST_GROUP first.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/