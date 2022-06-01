-- Activates the standard output for the current session.
SET SERVEROUTPUT ON;

CALL DBMS_OUTPUT.PUT_LINE('4 Queens');
CALL N_QUEENS(4);

CALL DBMS_OUTPUT.PUT_LINE('8 Queens');
CALL N_QUEENS(8);

CALL DBMS_OUTPUT.PUT_LINE('16 Queens');
CALL N_QUEENS(16);

