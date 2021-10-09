DECLARE
isPrivilegedUser VARCHAR2(255);
vExist NUMBER;
user_exist EXCEPTION;
tbs_exist EXCEPTION;
PRAGMA EXCEPTION_INIT(user_exist, -1918);
PRAGMA EXCEPTION_INIT(tbs_exist, -959);
BEGIN
    dbms_output.put_line('Cleaning up the database...');

    SELECT user into isPrivilegedUser FROM dual
    JOIN user_role_privs ON user=username
    WHERE granted_role='DBA';

    BEGIN
      EXECUTE IMMEDIATE 'DROP user SABDADM CASCADE';
      dbms_output.put_line('SABDADM user was dropped');
    EXCEPTION
      WHEN user_exist THEN
      dbms_output.put_line('SABDADM user does not exit');
    END;

    BEGIN
      EXECUTE IMMEDIATE 'DROP user SABDUSER CASCADE';
      dbms_output.put_line('SABDUSER user was dropped');
    EXCEPTION
      WHEN user_exist THEN
      dbms_output.put_line('SABDUSER user does not exit');
    END;

    SELECT count(*) INTO vExist FROM DBA_USERS WHERE username IN('SABDADM','SABDUSER');

    IF vExist > 0 THEN
          dbms_output.put_line('Cannot drop tablespace SABD_TBS. Schemas that use it exists');
    ELSE
      BEGIN
        EXECUTE IMMEDIATE 'DROP TABLESPACE SABD_TBS INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS';
        dbms_output.put_line('Tablespace SABD_TBS was dropped');
      EXCEPTION
        WHEN tbs_exist THEN
            dbms_output.put_line('Tablespace SABD_TBS does not exist');
      END;
    END IF;


EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(-20111, isPrivilegedUser||' is not a privileged user. Run prerequisites with a privileged user with DBA role.');

    WHEN OTHERS THEN
       dbms_output.put_line('Unexpected error occurred...');
       dbms_output.put_line(substr(DBMS_UTILITY.format_error_stack,1,2000));
END;
/