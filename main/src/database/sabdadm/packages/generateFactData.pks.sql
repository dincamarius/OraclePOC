CREATE OR REPLACE PACKAGE generateFactData AUTHID DEFINER IS

    -- constants declaration
    bacth_limit CONSTANT POSITIVE := 100;

    -- variables declaration
    v_count NUMBER;
    v_maxDate DATE;

    -- procedures declaration
    PROCEDURE load_FACT_DAY_RATES(mnt_in IN NUMBER DEFAULT 1);
    PROCEDURE update_FACT_DAY_RATES( nr_rows IN NUMBER);
    PROCEDURE load_FACT_TRANSACTIONS(mnt_in IN NUMBER DEFAULT 1);

    -- types
    TYPE trans_nt IS TABLE OF FACT_TRANSACTIONS%ROWTYPE;
    TYPE trans_rc IS REF CURSOR RETURN FACT_TRANSACTIONS%ROWTYPE;

    -- functions declaration
    FUNCTION f_get_TRANSACTIONS(mnt_in IN NUMBER DEFAULT 1) RETURN trans_nt;
    FUNCTION f_get_TRANSACTIONS_PL(mnt_in IN NUMBER DEFAULT 1) RETURN trans_nt PIPELINED;
    FUNCTION f_get_TRANSACTIONS_PL2( c_trans trans_rc) RETURN trans_nt PIPELINED;



END generateFactData;
/