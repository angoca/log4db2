--#SET TERMINATOR @

/**
 * Tests for the conf loggers effective table.
 */

SET CURRENT SCHEMA LOGGER_1A @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE LAST_VALUE ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
--DECLARE CURRENT_VALUE ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE RAISED_LG0E1 BOOLEAN DEFAULT FALSE; -- Logger without parent.
DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- Modifying values.
DECLARE RAISED_LG0E3 BOOLEAN DEFAULT FALSE; -- Modifying level_id.
DECLARE RAISED_LG0E4 BOOLEAN DEFAULT FALSE; -- ROOT logger should always exist.
DECLARE RAISED_530 BOOLEAN DEFAULT FALSE; -- Foreign key.
DECLARE ACTUAL_LOGGER ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_PARENT ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE EXPECTED_LOGGER ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_PARENT ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE STMT STATEMENT;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0E1 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0E2 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E3'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0E3 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E4'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0E4 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23503'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_530 = TRUE;
  END;
-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfLoggersEffective: Preparing environment');
SET LAST_VALUE = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;
COMMIT;

-- Test1: Inserts a normal logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test1: Inserts a normal logger');
SET EXPECTED_LOGGER = LAST_VALUE + 1;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test1', EXPECTED_PARENT, EXPECTED_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test2: Inserts a logger with a given id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test2: Inserts a logger with a given id');
SET EXPECTED_LOGGER = LAST_VALUE + 2;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
PREPARE STMT FROM 'INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) '
  || 'VALUES (' || EXPECTED_LOGGER || ', ''test2'', ' || EXPECTED_PARENT || ', ' || EXPECTED_LEVEL || ')';
EXECUTE STMT;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test3: Inserts a logger with a null id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test3: Inserts a logger with a null id');
SET EXPECTED_LOGGER = LAST_VALUE + 3;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
PREPARE STMT FROM 'INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) '
  || 'VALUES (NULL, ''test3'', ' || EXPECTED_PARENT || ', ' || EXPECTED_LEVEL || ')';
EXECUTE STMT;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test4: Inserts a logger with a negative id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test4: Inserts a logger with a negative id');
SET EXPECTED_LOGGER = LAST_VALUE + 4;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
PREPARE STMT FROM 'INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) '
  || 'VALUES (-1, ''test4'', ' || EXPECTED_PARENT || ', ' || EXPECTED_LEVEL || ')';
EXECUTE STMT;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test5: Inserts a logger with an inexistent parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test5: Inserts a logger with an inexistent parent');
SET ACTUAL_PARENT = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ + 5;
SET ACTUAL_LEVEL = 3; -- Default level
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test5', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_530 = FALSE;
COMMIT;

-- Test6: Inserts a logger with an null parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test6: Inserts a logger with an null parent');
SET ACTUAL_PARENT = NULL;
SET ACTUAL_LEVEL = 3; -- Default level
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test6', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_LG0E1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E1 = FALSE;
COMMIT;

-- Test6: Inserts a logger with an null parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test7: Inserts a logger with an null parent giving an id');
SET ACTUAL_LOGGER = 1;
SET ACTUAL_PARENT = NULL;
SET ACTUAL_LEVEL = 3; -- Default level
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) VALUES
  (ACTUAL_LOGGER, 'test7', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_LG0E1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E1 = FALSE;
COMMIT;

-- Test8: Inserts a logger with an null level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test8: Inserts a logger with an null level');
SET EXPECTED_LOGGER = LAST_VALUE + 6;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
SET ACTUAL_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test8', EXPECTED_PARENT, ACTUAL_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test9: Inserts a logger with an inexistent level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test9: Inserts a logger with an inexistent level');
SET EXPECTED_LOGGER = LAST_VALUE + 7;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 10;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test9', ACTUAL_PARENT, ACTUAL_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test10: Updates a normal logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Updates a normal logger');
SET EXPECTED_LOGGER = LAST_VALUE + 8;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
SET ACTUAL_LEVEL = 10;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test10', EXPECTED_PARENT, EXPECTED_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = ACTUAL_LEVEL
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test11: Updates a logger with a given id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Updates a logger with a given id');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 0;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test11', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ + 1
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E2 = FALSE;
COMMIT;

-- Test12: Updates a logger with a null id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Updates a logger with a null id');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 0;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test12', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LOGGER_ID = NULL
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E2 = FALSE;
COMMIT;

-- Test13: Updates a logger with a negative id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test13: Updates a logger with a negative id');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 0;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test13', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LOGGER_ID = -1
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E2 = FALSE;
COMMIT;

-- Test14: Updates a logger with an inexistent parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test14: Updates a logger with an inexistent parent');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 0;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test14', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET PARENT_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ + 1
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E2 = FALSE;
COMMIT;

-- Test15: Updates a logger with an null parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test15: Updates a logger with an null parent');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 0;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test15', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET PARENT_ID = NULL
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (RAISED_LG0E1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E1 = FALSE;
COMMIT;

-- Test16: Updates a logger with an null level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test16: Updates a logger with an null level');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 0;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test16', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = NULL
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (RAISED_LG0E3 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E3 = FALSE;
COMMIT;

-- Test17: Updates a logger with an inexistent level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test17: Updates a logger with an inexistent level');
SET EXPECTED_LOGGER = LAST_VALUE + 8;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test17', ACTUAL_PARENT, 0);
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = -1
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test18: Deletes a normal level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test18: Deletes a normal level');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test18', ACTUAL_PARENT, ACTUAL_LEVEL);
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = PREVIOUS VALUE FOR LOGDATA.LOGGER_ID_SEQ;
COMMIT;

-- Test19: Tries to delete root logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test19: Tries to delete root logger');
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (RAISED_LG0E4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E4 = FALSE;
COMMIT;

-- Test20: Delete all loggers except root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test20: Delete all loggers except root');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test20', ACTUAL_PARENT, ACTUAL_LEVEL);
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;
COMMIT;

-- Test21: Tries to delete all loggers.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test21: Tries to delete all loggers');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test21', ACTUAL_PARENT, ACTUAL_LEVEL);
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
IF (RAISED_LG0E4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
END IF;
SET RAISED_LG0E4 = FALSE;
COMMIT;

-- Test22: Updates root logger when it is the only existing to other id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test22: Updates root logger when it is the only existing to other id');
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test22', ACTUAL_PARENT, ACTUAL_LEVEL);
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LOGGER_ID = 1
  WHERE LOGGER_ID = 0;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfLoggersEffective: Finished succesfully');
COMMIT;

END @

SELECT *
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE@