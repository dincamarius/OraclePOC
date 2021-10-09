
DECLARE
vExist VARCHAR(255);
vCreateSeq VARCHAR2(2000);
BEGIN
    dbms_output.put_line('Creating sequences for primary keys tables...');
    FOR seq IN (select TABLE_NAME from user_constraints 
                JOIN USER_TABLES USING(TABLE_NAME)
                where constraint_type='P')
    LOOP
        BEGIN
            SELECT sequence_name INTO vExist FROM user_sequences WHERE sequence_name=upper(seq.TABLE_NAME)||'_SEQ';
            IF vExist IS NOT NULL THEN
                dbms_output.put_line('Sequence already exist => '|| vExist);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            vCreateSeq := 'CREATE SEQUENCE '||seq.TABLE_NAME||'_SEQ MINVALUE 1 MAXVALUE 999999999999999999999999999 START WITH 1 INCREMENT BY 1';
            EXECUTE IMMEDIATE vcreateseq;
        END;
    END LOOP;
    dbms_output.put_line('Done.');

EXCEPTION
    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));
END;
/