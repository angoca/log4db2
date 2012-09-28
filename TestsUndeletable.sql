/**
 * Tests for the undeletable root trigger.
 */

--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE GENERATED_ID ANCHOR DATA TYPE TO CONF_LOGGERS.LOGGER_ID; -- Generated id for the logger.
DECLARE RAISED BOOLEAN; -- For a controlled error.

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG003' SET RAISED = TRUE;
-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING, SQLEXCEPTION, NOT FOUND
  INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
SET RAISED = FALSE;
INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'TestUndeletable: Preparing environment');

-- Test1: Deletes a normal level.
INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'Test1: Deletes a normal level');
SELECT LOGGER_ID INTO GENERATED_ID FROM FINAL TABLE (
  INSERT INTO CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('TEST1', 0, 0));
DELETE FROM CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = GENERATED_ID;

-- Test2: Tries to delete root logger.
INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'Test2: Tries to delete root logger');
DELETE FROM CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (RAISED = FALSE) THEN
 INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'Exception not raised');
END IF;
SET RAISED = FALSE;

-- Test3: Delete all loggers except root.
INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'Test3: Delete all loggers except root');
INSERT INTO CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('TEST3', 0, 0);
DELETE FROM CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;

-- Test4: Tries to delete all loggers.
INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'Test4: Tries to delete all loggers');
DELETE FROM CONF_LOGGERS_EFFECTIVE;
IF (RAISED = FALSE) THEN
 INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'Exception not raised');
END IF;
SET RAISED = FALSE;

-- Cleans the environment.
INSERT INTO LOGS VALUES (CURRENT TIMESTAMP, 0, 0, SYSPROC.MON_GET_APPLICATION_ID() || '-' || SESSION_USER, 'TestUndeletable: Finished succesfully');

END