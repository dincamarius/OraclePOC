SET serveroutput on
SET pagesize 5000
SET long 5000
SET pages 500
SET linesize 300
SET echo on
SET serveroutput on
--WHENEVER SQLERROR EXIT

prompt ##########################################
prompt ###### Start deploying SABD project ######
prompt ##########################################
prompt

-- Setting deploy variables
define srcDB_path='../../src/database'
define adminSABD='SABDADM'
define userSABD='SABDUSER'
define passAdmSABD='SABDADM'
define passUserSABD='SABDUSER'

prompt _____________________________________________________________
prompt >>>  STEP 0 => Running prerequisites with dba role user  <<<
prompt _____________________________________________________________
SET feedback off
EXECUTE dbms_output.put_line('Connected user is '||USER);
--SET feedback on
@runWithDba.sql
prompt
prompt
SET feedback off;
EXECUTE dbms_lock.sleep(2);
SET feedback on;

connect &&adminSABD/&&passAdmSABD
SET serveroutput on
prompt ______________________________________________
prompt >>>  STEP 1 => Creating SABDADM objects  <<<
prompt ______________________________________________
SET feedback off
EXECUTE dbms_output.put_line('Connected user is '||USER);
SET feedback on
@sabdadm/master.sql

connect &&userSABD/&&passUserSABD
SET serveroutput on
prompt ______________________________________________
prompt >>>  STEP 2 => Creating SABDUSER objects  <<<
prompt ______________________________________________
SET feedback off
EXECUTE dbms_output.put_line('Connected user is '||USER);
SET feedback on
@sabduser/master.sql


EXECUTE dbms_output.put_line('Deploy process finished!');
--exit

