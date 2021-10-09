CREATE OR REPLACE PACKAGE utils AUTHID CURRENT_USER IS

  -- variables


  -- procedures
  PROCEDURE initialize(context_in IN VARCHAR2 DEFAULT NULL);
  PROCEDURE show_results(message_in IN VARCHAR2 DEFAULT NULL);

  -- functions
  FUNCTION mem_consumed(type_mem IN VARCHAR2) RETURN NUMBER;

END utils;
/