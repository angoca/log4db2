--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

/**
 * Tests for the conf_appenders table.
 */

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_LG004 BOOLEAN; -- For a controlled error.
DECLARE RAISED_407 BOOLEAN; -- Not null.
DECLARE RAISED_530 BOOLEAN; -- Foreign key.

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG004' SET RAISED_LG004 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502' SET RAISED_407 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23503' SET RAISED_530 = TRUE;
-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGS (MESSAGE) VALUES ('Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGS (MESSAGE) VALUES ('Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGS (MESSAGE) VALUES ('Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGS (MESSAGE) VALUES ('TestsConfAppenders: Preparing environment');
SET RAISED_LG004 = FALSE;
SET RAISED_407 = FALSE;
SET RAISED_530 = FALSE;
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  ((SELECT COALESCE(MAX(REF_ID)+1, 1) FROM CONF_APPENDERS), 'test1', 1, '%m');
DELETE FROM CONF_APPENDERS;

-- Test1: Inserts a normal appender_ref configuration.
INSERT INTO LOGS (MESSAGE) VALUES ('Test1: Inserts a normal appender_ref configuration');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (1, 'test1', 1, '%m');

-- Test2: Inserts an appender_ref with null appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test2: Inserts an appender_ref with null appender_id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (2, 'test2', NULL, '%m');
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test3: Inserts an appender_ref with inexistent appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test3: Inserts an appender_ref with inexistent appender_id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (3, 'test3', 0, '%m');
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_530 = FALSE;

-- Test4: Inserts an appender_ref with negative id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test4: Inserts an appender_ref with negative id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (-1, 'test4', 1, '%m');
IF (RAISED_LG004 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG004 = FALSE;

-- Test5: Inserts an appender_ref with null id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test5: Inserts an appender_ref with null id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (NULL, 'test5', 1, '%m');
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test6: Updates an appender_ref with null appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test6: Updates an appender_ref with null appender_id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (6, 'test6', 1, '%m');
UPDATE CONF_APPENDERS
  SET APPENDER_ID = NULL
  WHERE REF_ID = 6;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test7: Updates an appender with inexistent appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test7: Updates an appender_ref with inexistent appender_id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (7, 'test7', 1, '%m');
UPDATE CONF_APPENDERS
  SET APPENDER_ID = 0
  WHERE REF_ID = 7;
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_530 = FALSE;

-- Test8: Updates an appender_ref with negative id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test8: Updates an appender_ref with negative id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (8, 'test8', 1, '%m');
UPDATE CONF_APPENDERS
  SET REF_ID = -1
  WHERE REF_ID = 8;
IF (RAISED_LG004 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG004 = FALSE;

-- Test9: Updates an appender_ref with null id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test9: Updates an appender_ref with null id');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (9, 'test9', 1, '%m');
UPDATE CONF_APPENDERS
  SET REF_ID = NULL
  WHERE REF_ID = 9;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test10: Updates an appender_ref normally.
INSERT INTO LOGS (MESSAGE) VALUES ('Test10: Updates an appender_ref normally');
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES
  (10, 'test10', 1, '%m');
UPDATE CONF_APPENDERS
  SET REF_ID = 11
  WHERE REF_ID = 10;

-- Cleans the environment.
INSERT INTO LOGS (MESSAGE) VALUES ('TestsConfAppenders: Cleaning environment');
DELETE FROM CONF_APPENDERS;
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION,
  PATTERN)
  VALUES (1, 'DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGS (MESSAGE) VALUES ('TestsConfAppenders: Finished succesfully');

COMMIT;

END @