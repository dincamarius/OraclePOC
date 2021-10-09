DECLARE
v_adm_user VARCHAR2(30 CHAR) := 'SABDADM';
v_oper_code TVARCHAR := tvarchar('DEPOSIT','WITHDRAWAL','BANK TRANSFER','SHARES INVESTMENT','BOND INVESTMENT','MUTUAL FONDS INVESTMENT');
v_oper_desc TVARCHAR := tvarchar('Represent a money deposit transaction',
                                'Represent a money withdrawal transaction',
                                'Represent a money transfer between two accounts',
                                'Represent a share buy or share sale transaction',
                                'Represent a bond buy or bond sale transaction',
                                'Represent a mutual fond buy or mutual fond sale transaction');
v_account_types TVARCHAR := tvarchar('CURRENT ACCOUNT','CREDIT CARD','OVERDRAFT','CREDIT ACCOUNT','INVESTMENT ACCOUNT');

wrongUser EXCEPTION;
no_table EXCEPTION;

PRAGMA EXCEPTION_INIT(no_table, -942);

BEGIN
  IF USER = v_adm_user THEN

  FOR l_row IN 1..3
  LOOP
    FOR a_row IN 1..4
    LOOP
      INSERT INTO DIM_OPERATION VALUES(v_account_types(a_row),v_oper_code(l_row),v_oper_desc(l_row));
    END LOOP;
  END LOOP;
  COMMIT;

  FOR l_row IN 4..v_oper_code.count
  LOOP
    FOR a_row IN 5..v_account_types.count
    LOOP
      INSERT INTO DIM_OPERATION VALUES(v_account_types(a_row),v_oper_code(l_row),v_oper_desc(l_row));
    END LOOP;
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