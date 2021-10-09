
DECLARE

vStatus VARCHAR(255) := 'VALID';
vFound NUMBER;

BEGIN
    dbms_output.put_line(chr(9));
    dbms_output.put_line('>>>>>>     RUNNING BUILD TESTS     <<<<<<');

    -- Test 1 > checking for invalid objects
    dbms_output.put_line(chr(10));
    dbms_output.put_line('Test 1: Checking for invalid objects...');
    SELECT count(*) INTO vFound FROM user_objects WHERE status<>vStatus;

    IF vFound = 0 THEN
    dbms_output.put_line('Test 1: PASSED!');
    ELSE
      dbms_output.put_line('Found '||vFound||' invalid objects:');
      dbms_output.put_line(chr(9));
      FOR r IN (SELECT OBJECT_NAME, OBJECT_TYPE, CREATED, STATUS FROM user_objects
                WHERE status <> vStatus)
      LOOP
        dbms_output.put_line(r.OBJECT_TYPE||' '||r.OBJECT_NAME||' created on '||r.CREATED||' is '||r.STATUS);
      END LOOP;
    dbms_output.put_line(chr(9));
    dbms_output.put_line('Test 1: FAILED !!!');
    END IF;

    -- Test 2 > :)
--     dbms_output.put_line(chr(10));
--     dbms_output.put_line('Test 2: :(');
--     dbms_output.put_line('Test 2: what else to test???');

EXCEPTION
    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));
END;
/