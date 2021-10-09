DECLARE
vTablespace VARCHAR2(255) := 'SABD_TBS';
vUser VARCHAR2(255) := 'SABDUSER';
vExist VARCHAR2(255);
TYPE grantsType IS TABLE OF VARCHAR2(255);
vObjects grantsType :=grantsType('TABLE','SEQUENCE','TRIGGER','SYNONYM','VIEW','MATERIALIZED VIEW','PROCEDURE');
BEGIN

    SELECT USERNAME INTO vExist FROM DBA_USERS WHERE USERNAME=vUser;
    IF vExist IS NOT NULL THEN
        dbms_output.put_line('User already exist => '|| vExist);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        EXECUTE IMMEDIATE 'CREATE USER '||vUser||' IDENTIFIED BY '||vUser||' DEFAULT TABLESPACE '||vTablespace||' QUOTA UNLIMITED ON '||vTablespace||' TEMPORARY TABLESPACE TEMP';
        dbms_output.put_line('User '||vUser||' created');
        dbms_output.put_line('Giving necessary grants to '||vUser||'...');
        EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE SESSION TO '|| vUser;
        FOR elem in 1 .. vObjects.count LOOP
            EXECUTE IMMEDIATE ' GRANT CREATE '||vObjects(elem)||' TO '||vUser;
        END LOOP;
        dbms_output.put_line('Done.');


    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));
END;
/