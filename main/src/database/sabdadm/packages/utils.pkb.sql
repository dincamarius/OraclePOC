CREATE OR REPLACE PACKAGE BODY utils
IS

last_timing INTEGER := NULL;
last_pga INTEGER := NULL;
last_uga INTEGER := NULL;
pga_mem VARCHAR2(255) := 'session pga memory';
uga_mem VARCHAR2(255) := 'session uga memory';

FUNCTION mem_consumed(type_mem IN VARCHAR2) RETURN NUMBER AS -- type_mem='session pga memory' OR type_mem='session uga memory'
l_mem NUMBER;
BEGIN
  SELECT  st.value INTO l_mem
  FROM v$mystat st, v$statname sn
  WHERE st.statistic# = sn.statistic#
  AND sn.name=type_mem;

  RETURN l_mem;
END mem_consumed;

PROCEDURE initialize(context_in IN VARCHAR2 DEFAULT NULL) IS
v_user VARCHAR2(255 CHAR);
BEGIN

    SELECT user INTO v_user FROM dual;
    IF v_user = 'SABDADM' THEN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE TEST1';
    END IF;

  dbms_output.put_line('Getting statistics for '||context_in);
  last_timing := dbms_utility.get_time;
  last_pga := mem_consumed(pga_mem);
  last_uga := mem_consumed(uga_mem);

END initialize;

PROCEDURE show_results (message_in IN VARCHAR2 DEFAULT NULL) IS
l_count NUMBER;
BEGIN

  dbms_output.put_line(
      '"'||message_in||'" completed in: '||
      to_char((dbms_utility.get_time-last_timing)/100)||' sec === pga memory consumed: '||
      to_char(round((mem_consumed(pga_mem) - last_pga)/1024/1024,4))||' Mb === uga memory consumed: '||
      to_char(round((mem_consumed(uga_mem) - last_uga)/1024/1024,4))||' Mb'
  );
END show_results;

END utils;
/