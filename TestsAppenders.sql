--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

/**
 * Tests for the appenders table.
 */

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_LG005 BOOLEAN; -- For a controlled error.
DECLARE RAISED_407 BOOLEAN; -- Not null.

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG005' SET RAISED_LG005 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502' SET RAISED_407 = TRUE;
-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGS (MESSAGE) VALUES ('Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGS (MESSAGE) VALUES ('Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGS (MESSAGE) VALUES ('Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGS (MESSAGE) VALUES ('TestsAppenders: Preparing environment');
SET RAISED_LG005 = FALSE;
SET RAISED_407 = FALSE;
DELETE FROM APPENDERS;

-- Test1: Inserts a normal appender configuration.
INSERT INTO LOGS (MESSAGE) VALUES ('Test1: Inserts a normal appender configuration');
INSERT INTO APPENDERS (APPENDER_ID, NAME) VALUES
  (1, 'test1');

-- Test2: Inserts an appender with null appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test2: Inserts an appender with null appender_id');
INSERT INTO APPENDERS (APPENDER_ID, NAME) VALUES
  (NULL, 'test2');
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test3: Inserts an appender with negative appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test3: Inserts an appender with negative appender_id');
INSERT INTO APPENDERS (APPENDER_ID, NAME) VALUES
  (-1, 'test3');
IF (RAISED_LG005 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG005 = FALSE;

-- Test4: Updates an appender with null appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test4: Updates an appender with null appender_id');
INSERT INTO APPENDERS (APPENDER_ID, NAME) VALUES
  (4, 'test4');
UPDATE APPENDERS
  SET APPENDER_ID = NULL
  WHERE APPENDER_ID = 4;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test5: Updates an appender with negative appender_id.
INSERT INTO LOGS (MESSAGE) VALUES ('Test5: Updates an appender with negative appender_id');
INSERT INTO APPENDERS (APPENDER_ID, NAME) VALUES
  (5, 'test5');
UPDATE APPENDERS
  SET APPENDER_ID = -1
  WHERE APPENDER_ID = 5;
IF (RAISED_LG005 = FALSE) THEN
 INSERT INTO LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG005 = FALSE;

-- Test6: Updates an appender normally.
INSERT INTO LOGS (MESSAGE) VALUES ('Test6: Updates an appender normally');
INSERT INTO APPENDERS (APPENDER_ID, NAME) VALUES
  (6, 'test6');
UPDATE APPENDERS
  SET APPENDER_ID = 7
  WHERE APPENDER_ID = 6;

-- Cleans the environment.
INSERT INTO LOGS (MESSAGE) VALUES ('TestsAppenders: Cleaning environment');
DELETE FROM APPENDERS;
INSERT INTO APPENDERS (APPENDER_ID, NAME)
  VALUES (1, 'Pure SQL PL - Tables'),
         (2, 'db2diag.log'),
         (3, 'UTL_FILE'),
         (4, 'DB2 logger'),
         (5, 'Java logger');
INSERT INTO LOGS (MESSAGE) VALUES ('TestsAppenders: Finished succesfully');

END @