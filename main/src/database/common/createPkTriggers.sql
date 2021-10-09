DECLARE
vCreateTrg VARCHAR2(2000);
BEGIN
dbms_output.put_line('Creating triggers for PKs columns...');
    FOR trg IN (SELECT sequence_name seqnm, TRGNAME, tabname, pkcol FROM user_sequences
                JOIN (
                SELECT trigger_name TRGNAME, uc.table_name TABNAME, ucc.column_name PKCOL
                                FROM user_cons_columns ucc
                                JOIN user_constraints uc USING (constraint_name)
                                LEFT JOIN user_triggers ut ON uc.table_name=ut.table_name
                                WHERE uc.constraint_type='P') pkcon
                ON substr(sequence_name,1,length(sequence_name)-4) = pkcon.tabname)
    LOOP
        IF trg.TRGNAME IS NULL THEN
            vCreateTrg :=  'CREATE OR REPLACE TRIGGER '||trg.TABNAME||'_PK_TRG
                            BEFORE INSERT ON '||trg.TABNAME||'
                            FOR EACH ROW
                            WHEN (new.'||trg.PKCOL||' IS NULL) BEGIN
                            :new.'||trg.PKCOL||' := '||trg.seqnm||'.NEXTVAL;
                            END;';
            EXECUTE IMMEDIATE vCreateTrg;
            EXECUTE IMMEDIATE 'ALTER TRIGGER '||trg.TABNAME||'_PK_TRG ENABLE';
        ELSE
            dbms_output.put_line('Trigger already exist => '|| trg.TRGNAME);
        END IF;
    END LOOP;
    dbms_output.put_line('Done.');

EXCEPTION
    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));
END;
/