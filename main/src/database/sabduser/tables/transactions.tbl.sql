DECLARE
v_user VARCHAR2(30 CHAR) := 'SABDUSER';
createTbl VARCHAR(4000 CHAR);
wrongUser EXCEPTION;
tbl_exist EXCEPTION;
fk_exception EXCEPTION;

PRAGMA EXCEPTION_INIT(tbl_exist, -955);
PRAGMA EXCEPTION_INIT(fk_exception, -942);

BEGIN
  IF USER = v_user THEN

  createTbl := 'CREATE TABLE TRANSACTIONS (
    TRAN_KEY NUMBER,
    TRAN_DATE DATE DEFAULT trunc(SYSDATE),
    DATE_KEY VARCHAR2(8 CHAR),
    IS_BSNS_DT VARCHAR2(1 CHAR) CHECK (IS_BSNS_DT IN (''Y'',''N'')),
    SOURCE_ACCOUNT_KEY NUMBER,
    SOURCE_CUSTOMER_KEY NUMBER,
    TARGET_ACCOUNT_KEY NUMBER,
    TARGET_CUSTOMER_KEY NUMBER,
    COMMISSION_CCY VARCHAR2(3) DEFAULT ''EUR'',
    SOURCE_CCY VARCHAR2(3),
    TARGET_CCY VARCHAR2(3),
    EXCHANGE_RATE_SRC_TGT NUMBER(5,2),
    EXCHANGE_RATE_COMM NUMBER(5,2),
    OPERATION_CODE VARCHAR2(255 CHAR),
    AMOUNT_IN_SRC_CCY NUMBER(22,2),
    COMMISSION NUMBER(22,2),
    AMOUNT_IN_TGT_CCY NUMBER(22,2),
    CONSTRAINT TRAN_PK PRIMARY KEY(TRAN_KEY),
    FOREIGN KEY(SOURCE_ACCOUNT_KEY) REFERENCES ACCOUNTS(ACCOUNT_ID),
    FOREIGN KEY(TARGET_ACCOUNT_KEY) REFERENCES ACCOUNTS(ACCOUNT_ID),
    FOREIGN KEY(SOURCE_CUSTOMER_KEY) REFERENCES CUSTOMERS(CUSTOMER_ID),
    FOREIGN KEY(TARGET_CUSTOMER_KEY) REFERENCES CUSTOMERS(CUSTOMER_ID)
  )';

  EXECUTE IMMEDIATE createTbl;
  dbms_output.put_line('Table TRANSACTIONS created');

  DBMS_ERRLOG.CREATE_ERROR_LOG('TRANSACTIONS','ERR_TRANSACTIONS');
  dbms_output.put_line('Table ERR_TRANSACTIONS created');

  ELSE
    RAISE wrongUser;
  END IF;

EXCEPTION
    WHEN wrongUser THEN
    dbms_output.put_line('ERROR: Connected user is not '||v_user);

    WHEN tbl_exist THEN
      dbms_output.put_line('ERROR: Table already exist');

    WHEN fk_exception THEN
      dbms_output.put_line('ERROR: Cannot create foreign key, referenced table does not exist.');
      dbms_output.put_line('TODO: Create tables ACCOUNTS and CUSTOMERS first.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/

