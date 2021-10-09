CREATE OR REPLACE PROCEDURE load_ERROR_TABLE_LOG(v_date IN DATE DEFAULT trunc(SYSDATE), v_table IN VARCHAR2) AUTHID DEFINER IS

    l_data err_data_nt := err_data_nt();
    v_identifier VARCHAR2(255);
    col_identifier VARCHAR2(255);

BEGIN

    SELECT substr(v_table,instr(v_table,'_')+1,length(v_table)-5) INTO v_identifier FROM dual;
    SELECT column_name INTO col_identifier FROM user_tab_columns WHERE table_name=v_table AND column_id=6;

    EXECUTE IMMEDIATE '
        SELECT err_data_ob(
                ORA_ERR_TAG$,
               ''ORA-''||ORA_ERR_NUMBER$,
               substr(ORA_ERR_MESG$,11),
               '''||v_identifier||'_ID=''||'||col_identifier||'
               )
        FROM '||v_table BULK COLLECT INTO l_data;

    FORALL r IN l_data.first..l_data.last
    INSERT INTO ERROR_TABLE_LOG(ERROR_DATE, PROCESS_NAME, ERROR_CODE,ERROR_MESSAGE,ROW_IDENTIFIER)
    VALUES(
        v_date,
        l_data(r).PROCESS_NAME,
        l_data(r).ERROR_CODE,
        l_data(r).ERROR_MESSAGE,
        l_data(r).ROW_IDENTIFIER
    );
    COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
         dbms_output.put_line('ERROR: Unexpected error occurred...');
         dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END load_ERROR_TABLE_LOG;
/