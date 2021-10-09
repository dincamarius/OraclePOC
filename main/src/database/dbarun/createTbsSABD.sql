DECLARE
vTablespace VARCHAR2(255) := 'SABD_TBS';
vExist VARCHAR2(255);
vDataFile VARCHAR2(255);
vCreateTbs  VARCHAR2(2000);
BEGIN
    SELECT TABLESPACE_NAME INTO vExist FROM DBA_TABLESPACES WHERE TABLESPACE_NAME=vTablespace;
    IF vExist IS NOT NULL THEN
        dbms_output.put_line('Tablespace already exist => '|| vExist);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Creating tablespace '||vTablespace);
        SELECT regexp_replace(file_name,'SYSTEM','SABD') INTO vDataFile FROM dba_data_files WHERE tablespace_name='SYSTEM' FETCH FIRST 1 ROW ONLY;
        vCreateTbs := 'CREATE TABLESPACE '||vTablespace||' DATAFILE '''||vDataFile||''' SIZE 100M AUTOEXTEND ON';
        EXECUTE IMMEDIATE vCreateTbs;
        dbms_output.put_line('Done.');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));
END;
/