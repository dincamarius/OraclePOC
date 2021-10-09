create or replace PACKAGE generateDimData AUTHID DEFINER AS

    -- constants declaration
    bacth_limit CONSTANT POSITIVE := 1000;

    -- variables declaration
    v_country VARCHAR2(5 CHAR);
    v_currency VARCHAR2(5 CHAR);
    v_seq NUMBER;
    v_group NUMBER;
    v_name VARCHAR2(255 CHAR);
    v_surname VARCHAR2(255 CHAR);
    v_container VARCHAR2(255 CHAR);
    v_customerId NUMBER;
    v_count NUMBER;
    v_account_types TVARCHAR := tvarchar('CURRENT ACCOUNT','CREDIT CARD','OVERDRAFT','CREDIT ACCOUNT','INVESTMENT ACCOUNT');

    -- procedures declaration
    PROCEDURE load_DIM_DATE;
    PROCEDURE load_DIM_CUST_GROUP (in_rows IN NUMBER);
    PROCEDURE load_DIM_CUSTOMER (in_rows IN NUMBER);
    PROCEDURE load_DIM_ACCOUNT (in_rows IN NUMBER);

    -- types declaration

    -- functions declaration
    FUNCTION f_account_types RETURN TVARCHAR PIPELINED;

END generateDimData;

/