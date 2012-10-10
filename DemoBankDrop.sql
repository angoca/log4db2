--#SET TERMINATOR @
SET CURRENT SCHEMA DEMOBANK @

DROP PROCEDURE CLOSE_ACCOUNT (INTEGER) @

DROP PROCEDURE TRANSFER (INTEGER, INTEGER, INTEGER) @

DROP PROCEDURE WITHDRAWAL (INTEGER, INTEGER) @

DROP PROCEDURE DEPOSIT (INTEGER, INTEGER) @

DROP PROCEDURE GET_BALANCE (INTEGER, INTEGER) @

DROP PROCEDURE CREATE_ACCOUNT(VARCHAR(32), VARCHAR(32)) @

DROP TABLE TRANSACTIONS @

DROP TABLE ACCOUNTS @

DROP SCHEMA DEMOBANK RESTRICT @