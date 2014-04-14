--#SET TERMINATOR @

/*
Copyright (c) 2012 - 2014, Andres Gomez Casanova (AngocA)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * Tests for the logger suppresions (conf_logger table).
 */

SET CURRENT SCHEMA LOGGER_1B @

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", LOGGER_1B @

CREATE OR REPLACE FUNCTION GET_MAX_ID()
  RETURNS ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
 BEGIN
  DECLARE RET ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  SET RET = (SELECT MAX(LOGGER_ID)
    FROM LOGDATA.CONF_LOGGERS);
  RETURN RET;
 END@

CREATE OR REPLACE PROCEDURE DELETE_LAST_MESSAGE_FROM_TRIGGER()
 BEGIN
  DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = 'A manual CONF_LOGGERS_EFFECTIVE update should be realized.'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
 END @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_LG0C1 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C3 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0E4 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE ACTUAL_LOGGER ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_PARENT ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE ACTUAL_QTY SMALLINT;
DECLARE EXPECTED_LOGGER ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_PARENT ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE EXPECTED_QTY SMALLINT;
DECLARE TEMP ANCHOR TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE MAX_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (1, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C1 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C2'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (1, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C2 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C3'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (1, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C3 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0E2 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E4'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0E4 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsConfLoggerDelete: Preparing environment');
SET RAISED_LG0C1 = FALSE;
SET RAISED_LG0C2 = FALSE;
SET RAISED_LG0C3 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL DELETE_LAST_MESSAGE_FROM_TRIGGER();
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'internalCache';
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'logInternals';
SET TEMP = GET_MAX_ID();
COMMIT;

-- Test01: Tests to delete ROOT logger with a given level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test01: Tests to delete ROOT logger with a given level');
SET EXPECTED_LEVEL = NULL;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 5
  WHERE LOGGER_ID = 0;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = 0;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0E2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0E2');
END IF;
SET RAISED_LG0E2 = FALSE;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test02: Tests to delete ROOT logger with null level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Tests to delete ROOT logger with null level');
SET EXPECTED_LEVEL = NULL;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = NULL
  WHERE LOGGER_ID = 0;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = 0;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0E2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0E2');
END IF;
SET RAISED_LG0E2 = FALSE;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test03: Tests to delete all inserted loggers.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test03: Tests to delete all inserted loggers');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T3', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID();
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LEVEL = NULL;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL DELETE_LAST_MESSAGE_FROM_TRIGGER();
CALL LOGGER.REFRESH_CACHE();
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 5
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test3', 0, 3);
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0E2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0E2');
END IF;
SET RAISED_LG0E2 = FALSE;
SELECT COUNT(1) INTO EXPECTED_QTY
  FROM LOGDATA.CONF_LOGGERS;
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different QTY');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_QTY || ' - ' || ACTUAL_QTY);
END IF;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = EXPECTED_LOGGER;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test04: Tests to delete all null inserted logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test04: Tests to delete all null inserted logger');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T4', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID();
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LEVEL = NULL;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 2
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test40', 0, NULL);
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS;
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0E2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0E2');
END IF;
SET RAISED_LG0E2 = FALSE;
SELECT COUNT(1) INTO EXPECTED_QTY
  FROM LOGDATA.CONF_LOGGERS;
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different QTY');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_QTY || ' - ' || ACTUAL_QTY);
END IF;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = EXPECTED_LOGGER + 1;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test05: Tests to delete inserted logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test05: Tests to delete inserted logger');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T5', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID();
SET EXPECTED_QTY = 0;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LEVEL = NULL;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 5
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test5', 0, 3);
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = EXPECTED_LOGGER + 1;
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = EXPECTED_LOGGER + 1;
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different QTY');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_QTY || ' - ' || ACTUAL_QTY);
END IF;
SET EXPECTED_LEVEL = 5;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test06: Tests to delete null inserted logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test06: Tests to delete null inserted logger');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T6', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID();
SET EXPECTED_QTY = 0;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LEVEL = NULL;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 2
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test6', 0, NULL);
SET MAX_ID = GET_MAX_ID();
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = MAX_ID + 1;
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = MAX_ID + 1;
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different QTY');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_QTY || ' - ' || ACTUAL_QTY);
END IF;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = MAX_ID + 1;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LEVEL = 2;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
COMMIT;

-- Test07: Tests to delete ROOT logger cascade.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test07: Tests to delete ROOT logger cascade');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T7', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID();
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LEVEL = 3;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CACHE();
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 1
  WHERE LOGGER_ID = 0;
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'ROOT';
IF (RAISED_LG0E2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0E2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0E2');
END IF;
SET RAISED_LG0E2 = FALSE;
COMMIT;

-- Test08: Tests to delete a logger cascade.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test08: Tests to delete a logger cascade');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_QTY = 1;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 2
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test8a', 0, 1);
SET MAX_ID = GET_MAX_ID();
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test8b', MAX_ID, 2);
SET MAX_ID = GET_MAX_ID();
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test8c', MAX_ID, 4);
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'Test8a';
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGDATA.CONF_LOGGERS;
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different QTY');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_QTY || ' - ' || ACTUAL_QTY);
END IF;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfLoggerDelete: Cleaning environment');
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
  VALUES ('autonomousLogging', 'true'),
         ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfLoggerDelete: Finished succesfully');
COMMIT;

END @

DROP PROCEDURE DELETE_LAST_MESSAGE_FROM_TRIGGER() @

--SELECT LOGGER_ID, PARENT_ID, VARCHAR(NAME, 32) NAME, LEVEL_ID
--  FROM LOGDATA.CONF_LOGGERS
--  ORDER BY LOGGER_ID @

--SELECT LOGGER_ID, LEVEL_ID, HIERARCHY
--  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
--  ORDER BY LOGGER_ID @

