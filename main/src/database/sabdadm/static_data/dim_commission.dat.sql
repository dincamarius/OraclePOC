DECLARE
v_adm_user VARCHAR2(30 CHAR) := 'SABDADM';
v_oper_code TVARCHAR := tvarchar('DEPOSIT','WITHDRAWAL','BANK TRANSFER','SHARES INVESTMENT','BOND INVESTMENT','MUTUAL FONDS INVESTMENT');
v_boundary TNUMBER := tnumber(0,0,0,1000,500,100);

wrongUser EXCEPTION;
no_table EXCEPTION;

PRAGMA EXCEPTION_INIT(no_table, -955);

BEGIN
  IF USER = v_adm_user THEN

    FOR l_row IN 1..v_oper_code.count
    LOOP
      EXECUTE IMMEDIATE 'INSERT INTO DIM_COMMISSION VALUES('||l_row||','''||v_oper_code(l_row)||''','||v_boundary(l_row)||','''||(v_boundary(l_row)/100)||'%'',''EUR'')';
    END LOOP;
    COMMIT;

  ELSE
    RAISE wrongUser;
  END IF;

EXCEPTION
    WHEN wrongUser THEN
    dbms_output.put_line('ERROR: Connected user is not '||v_adm_user);

    WHEN no_table THEN
      dbms_output.put_line('ERROR: Table already exist');

    WHEN OTHERS THEN
     dbms_output.put_line('ERROR: Unexpected error occurred...');
     dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));

END;
/